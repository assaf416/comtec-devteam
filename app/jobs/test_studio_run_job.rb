require "open3"

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
    run.update!(status: :running, started_at: Time.current, output: "")

    # --no-profile: config/cucumber.yml's default profile always appends the
    # whole "features" directory as a path, which would silently run the
    # entire suite (merged with our single file) instead of just this file.
    cmd = [
      "bundle", "exec", "cucumber", "--no-profile", "--format", "progress", "--strict", "--tags", "not @wip",
      File.join("features", run.feature_path)
    ]

    buffer = +""
    exit_status = stream_output(cmd, run) { |chunk| buffer << chunk; run.update!(output: buffer) }

    run.update!(
      status: exit_status.success? ? :passed : :failed,
      output: buffer,
      finished_at: Time.current
    )
  rescue StandardError => e
    run.update!(status: :error, output: e.message, finished_at: Time.current)
  end

  private

  def stream_output(cmd, run)
    Open3.popen3(*cmd, chdir: Rails.root.to_s) do |stdin, stdout, stderr, wait_thr|
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
