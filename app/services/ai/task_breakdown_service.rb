module Ai
  # "Generate tasks and estimations" — breaks a story into precise, independently
  # estimable tasks, calibrating time estimates against the project's historical
  # estimate-vs-actual data. The controller parses the result into Task records.
  class TaskBreakdownService < BaseService
    KIND = :task_breakdown

    private

    def system_prompt
      <<~SYS
        You are a tech lead breaking a user story into precise, independently
        estimable engineering tasks (each ideally ≤ 1 day). Use the provided
        historical estimate-vs-actual data to calibrate realistic estimates — if
        the team historically underestimates, adjust upward accordingly.

        Output format — IMPORTANT, this is parsed automatically:
        First a one-line summary. Then a line containing exactly:
        TASKS:
        followed by one task per line in the form:
        - [<estimate>] <task description>
        where <estimate> is time like `2h`, `4h` or `1d`.
        Do not add any other bullet lists after the TASKS section.
      SYS
    end

    def build_prompt
      <<~TXT
        Break this story into estimated tasks:

        #{ticket_context(reviewable)}

        #{history_summary}

        Ground your time estimates in the historical data above where relevant.
      TXT
    end

    def history_summary
      project   = reviewable.project
      completed = project.tickets.where(status: [ :done, :closed ])
                         .where.not(dev_estimate_hours: nil).limit(10)
      rows = completed.filter_map do |t|
        act = t.actual_hours_in_hours
        "- \"#{t.title.truncate(50)}\": estimated #{t.dev_estimate_hours}h#{act ? ", actual #{act}h" : ''}"
      end
      return "No historical estimate data is available yet; use sensible defaults." if rows.empty?

      "Recent completed work on this project (estimate vs actual, for calibration):\n#{rows.join("\n")}"
    end

    # Parse the model output into [{ estimation:, description: }, …].
    # Only bullet/numbered lines after a `TASKS:` marker are considered (falling
    # back to all bullet lines if the marker is missing).
    def self.parse_tasks(text)
      body    = text.to_s
      scoped  = body =~ /^\s*TASKS:\s*$/i
      body    = body[Regexp.last_match.end(0)..] if scoped

      tasks = []
      body.each_line do |line|
        # When scoped to a TASKS: block, stop at the next markdown heading so we
        # don't pick up bullets from later sections (e.g. "## Risks").
        break if scoped && line.strip.start_with?("#")

        parsed = parse_task_line(line)
        tasks << parsed if parsed
      end
      tasks
    end

    def self.parse_task_line(line)
      l = line.strip
      return nil unless l.match?(/\A(?:[-*]|\d+[.)])\s+/)

      content = l.sub(/\A(?:[-*]|\d+[.)])\s+/, "")
      estimation = nil
      if (m = content.match(/\[([^\]]+)\]/))
        estimation = m[1].strip
        content = content.sub(/\[[^\]]+\]/, "")
      end
      content = content.sub(/\A[:\-–\s]+/, "").strip
      return nil if content.length < 3

      { estimation: estimation, description: content.truncate(255) }
    end
  end
end
