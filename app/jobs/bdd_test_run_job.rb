require "open3"
require "json"
require "tempfile"
require "shellwords"

# Runs one BddTest (a .feature file belonging to an external, possibly
# non-Ruby project) via that project's own configured cucumber_cmd, and
# records the result on a BddTestRun. Deliberately does NOT touch or share
# code with TestStudioRunJob (which runs this app's own internal suite) —
# see app/jobs/test_studio_run_job.rb for the proven streaming technique this
# copies, and the plan doc for why they're kept separate.
#
# Unlike TestStudioRunJob, this does NOT force RAILS_ENV=test: these are
# foreign toolchains (C#/dotnet, Node, JRuby, Ruby) that should inherit the
# QA machine's normal environment (PATH, JAVA_HOME, etc) as-is.
class BddTestRunJob < ApplicationJob
  queue_as :default

  # Foreign toolchains (JRuby/AS400 startup, hundreds of SOAP calls) are far
  # more likely to hang than this app's own suite, so unlike Test Studio this
  # needs a real timeout.
  MAX_DURATION = 30.minutes

  class TimedOut < StandardError; end

  def perform(run_id)
    run      = BddTestRun.find(run_id)
    bdd_test = run.bdd_test
    project  = bdd_test.project

    unless bdd_test.safe_path?
      run.update!(status: :error, output: "Refusing to run: path resolves outside the project's home_folder.", finished_at: Time.current)
      return
    end

    run.update!(status: :running, started_at: Time.current, output: "", structured_results: nil)

    json_file = Tempfile.new([ "bdd-test-run", ".json" ])
    json_file.close

    # NOTE: deliberately NOT requesting --format html here. Cucumber's own
    # html formatter (cucumber 10.2.0, pinned in this app's Gemfile.lock)
    # crashes with "undefined method 'map' for nil" in
    # Cucumber::Formatter::MessageBuilder#argument_group_to_message on ANY
    # scenario with a {string} step argument — confirmed with a minimal
    # English repro outside this app entirely, so it's an upstream gem bug,
    # not something fixable by changing step text. result_html is built
    # below from our own step_report partial instead.
    cmd = Shellwords.split(project.cucumber_cmd) + [
      "--format", "progress",
      "--format", "json", "--out", json_file.path,
      bdd_test.path
    ]

    buffer = +""
    exit_status = stream_output(cmd, project.home_folder) { |chunk| buffer << chunk; run.update!(output: buffer) }

    structured_results = parse_step_report(json_file.path)

    run.update!(
      status: exit_status.success? ? :passed : :failed,
      output: buffer,
      structured_results: structured_results,
      result_html: render_result_html(structured_results),
      command: cmd.join(" "),
      chdir: project.home_folder,
      finished_at: Time.current
    )
  rescue TimedOut
    run.update!(status: :error, output: "#{buffer}\n\n[timed out after #{MAX_DURATION.inspect}]", finished_at: Time.current)
  rescue StandardError => e
    run.update!(status: :error, output: e.message, finished_at: Time.current)
  ensure
    bdd_test&.update_columns(
      latest_bdd_test_run_id: run.id,
      latest_status: BddTestRun.statuses[run.status],
      latest_run_at: run.finished_at
    )
    json_file&.unlink
  end

  private

  # Renders our own step_report partial (the same one shown on the BDD Tests
  # pages) into a standalone HTML document, so BddTestRun#result_html holds
  # a real, self-contained HTML report — see the comment above on why we
  # don't use Cucumber's native --format html.
  def render_result_html(structured_results_json)
    return nil if structured_results_json.blank?

    report = JSON.parse(structured_results_json)
    body = ApplicationController.render(
      partial: "bdd_tests/step_report",
      locals: { report: report }
    )

    <<~HTML
      <!DOCTYPE html>
      <html dir="rtl" lang="he">
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: system-ui, sans-serif; margin: 16px; }
          .test-studio-step-report { margin-bottom: 10px; }
          .tsr-scenario { border: 1px solid #e2e5ea; border-radius: 8px; padding: 10px 14px; margin-bottom: 8px; background: #fff; }
          .tsr-scenario-name { font-weight: 700; margin-bottom: 6px; }
          .tsr-steps { list-style: none; margin: 0; padding: 0; }
          .tsr-step { display: flex; align-items: flex-start; gap: 6px; padding: 3px 0; font-size: .86rem; }
          .tsr-step-passed { color: #1a7f37; }
          .tsr-step-failed { color: #b42318; font-weight: 600; }
          .tsr-step-skipped, .tsr-step-undefined, .tsr-step-pending { color: #6b7280; }
          .tsr-error {
            direction: ltr; text-align: left; background: #fff5f5; border: 1px solid #f3c6c6;
            color: #b42318; border-radius: 6px; padding: 8px 10px; margin: 6px 0 0 0;
            font-size: .78rem; white-space: pre-wrap; width: 100%; font-family: ui-monospace, monospace;
          }
        </style>
      </head>
      <body>#{body}</body>
      </html>
    HTML
  rescue StandardError
    nil
  end

  # Reduces Cucumber's JSON formatter output to just what the step-report
  # partial needs — identical shape to TestStudioRunJob#parse_step_report.
  def parse_step_report(json_path)
    raw = JSON.parse(File.read(json_path))

    features = raw.map do |feature|
      {
        "name" => feature["name"],
        "elements" => Array(feature["elements"]).map do |element|
          {
            "keyword" => element["keyword"],
            "name"    => element["name"],
            "steps"   => Array(element["steps"]).map do |step|
              {
                "keyword"       => step["keyword"],
                "name"          => step["name"],
                "status"        => step.dig("result", "status"),
                "error_message" => step.dig("result", "error_message")
              }
            end
          }
        end
      }
    end

    features.to_json
  rescue StandardError
    nil
  end

  def stream_output(cmd, chdir)
    started_at = Time.current

    Open3.popen3(*cmd, chdir: chdir) do |stdin, stdout, stderr, wait_thr|
      stdin.close
      streams = [ stdout, stderr ]

      until streams.empty?
        if Time.current - started_at > MAX_DURATION
          begin
            Process.kill("TERM", wait_thr.pid)
          rescue Errno::ESRCH
            nil # already exited
          end
          wait_thr.value
          raise TimedOut
        end

        ready, = IO.select(streams, nil, nil, 1)
        (ready || []).each do |io|
          chunk = io.read_nonblock(8192).force_encoding(Encoding::UTF_8)
          yield chunk
        rescue EOFError
          streams.delete(io)
        rescue IO::WaitReadable
          next
        end
      end

      wait_thr.value
    end
  end
end
