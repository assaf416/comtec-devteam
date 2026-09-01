require "open3"
require "json"
require "tempfile"

# Runs one Cucumber feature file for the Test Studio pages and records the
# result on its TestStudioRun. Uses array-form Open3 args (no shell
# interpolation) — feature_path is already whitelisted by
# TestStudioController#safe_feature_path before a run is ever created.
#
# Output streams in as it's produced (rather than only at the end) so slow
# suites — e.g. one that shells out further to exercise an AS400/COBOL
# system — show live progress instead of a long silent wait.
class TestStudioRunJob < ApplicationJob
  queue_as :default

  def perform(run_id)
    run = TestStudioRun.find(run_id)
    run.update!(status: :running, started_at: Time.current, output: "", structured_results: nil)

    json_file = Tempfile.new([ "test-studio-run", ".json" ])
    json_file.close

    # --no-profile: config/cucumber.yml's default profile always appends the
    # whole "features" directory as a path, which would silently run the
    # entire suite (merged with our single file) instead of just this file.
    # A second --format writes the same run's results as JSON (in addition to
    # the live "progress" dots) so we can render a step-by-step report once
    # the run finishes.
    cmd = [
      "bundle", "exec", "cucumber", "--no-profile", "--format", "progress", "--strict", "--tags", "not @wip",
      "--format", "json", "--out", json_file.path,
      File.join("features", run.feature_path)
    ]

    buffer = +""
    exit_status = stream_output(cmd, run) { |chunk| buffer << chunk; run.update!(output: buffer) }

    run.update!(
      status: exit_status.success? ? :passed : :failed,
      output: buffer,
      structured_results: parse_step_report(json_file.path),
      finished_at: Time.current
    )
  rescue StandardError => e
    run.update!(status: :error, output: e.message, finished_at: Time.current)
  ensure
    json_file&.unlink
  end

  private

  # Reduces Cucumber's JSON formatter output to just what the step-report
  # partial needs (feature/scenario names, and each step's keyword/name/
  # status/error_message), so we don't store or render its heavier fields
  # (tags, line numbers, match locations, etc).
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

  # Force RAILS_ENV/RACK_ENV=test explicitly: this job runs inside the booted
  # (development) Rails server process, which already set ENV["RAILS_ENV"] to
  # "development" at boot — a subprocess spawned via Open3 inherits that, so
  # without this override cucumber-rails' own `ENV["RAILS_ENV"] ||= "test"`
  # is a no-op and every Test Studio run silently hits the development
  # database instead of an isolated one.
  SUBPROCESS_ENV = { "RAILS_ENV" => "test", "RACK_ENV" => "test" }.freeze

  def stream_output(cmd, run)
    Open3.popen3(SUBPROCESS_ENV, *cmd, chdir: Rails.root.to_s) do |stdin, stdout, stderr, wait_thr|
      stdin.close
      streams = [ stdout, stderr ]

      until streams.empty?
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
