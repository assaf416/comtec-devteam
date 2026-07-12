module Git
  # Assembles the "is this PR safe to merge?" picture from the signals we already
  # have (CI/tests, coverage, AI review) and a conflict check.
  #
  # A real git backend (Gitea/GitLab) would report mergeability + the conflicting
  # hunks; until that's wired up we synthesize a deterministic conflict set so the
  # resolver UI is exercisable. Swap #conflicting_files for the backend call later.
  class MergeService
    Analysis = Struct.new(:state, :conflicts, :checks, :coverage, :ai_verdict, keyword_init: true) do
      def mergeable? = state == "clean"
      def state_label
        { "clean" => "Ready to merge", "conflicts" => "Conflicts to resolve",
          "checks_failing" => "Checks failing", "merged" => "Merged",
          "closed" => "Closed" }.fetch(state, state.humanize)
      end
      def state_color
        { "clean" => "success", "conflicts" => "warning", "checks_failing" => "danger",
          "merged" => "secondary", "closed" => "secondary" }.fetch(state, "secondary")
      end
    end

    def analyze(pr)
      summary   = pr.test_summary.is_a?(Hash) ? pr.test_summary : {}
      total     = summary["total"].to_i
      failed    = summary["failed"].to_i
      conflicts = conflicting_files(pr)

      checks = {
        tests:    { ok: total.positive? && failed.zero?,
                    label: total.positive? ? "#{summary['passed']}/#{total} tests passing" : "No test data" },
        coverage: { ok: pr.coverage_percent.to_f >= 80.0,
                    label: pr.coverage_percent.present? ? "Coverage #{pr.coverage_percent}%" : "No coverage data" },
        review:   { ok: ai_verdict(pr) == "approved",
                    label: ai_verdict(pr) ? "AI review: #{ai_verdict(pr).humanize}" : "No AI review yet" },
        conflicts: { ok: conflicts.empty?,
                     label: conflicts.empty? ? "No merge conflicts" : "#{conflicts.size} file(s) conflict" }
      }

      state =
        if pr.status == "merged" then "merged"
        elsif pr.status == "closed" then "closed"
        elsif conflicts.any? then "conflicts"
        elsif !checks[:tests][:ok] then "checks_failing"
        else "clean"
        end

      Analysis.new(state: state, conflicts: conflicts, checks: checks,
                   coverage: pr.coverage_percent, ai_verdict: ai_verdict(pr))
    end

    # Deterministic synthetic conflicts (demo). Odd-numbered PRs "conflict" on
    # their first couple of changed source files; each gets ours/theirs blobs.
    def conflicting_files(pr)
      return [] unless pr.pr_number.to_i.odd?

      pr.pr_files.select { |f| f["path"].to_s.match?(/\.(rb|cs|js|ts|go|py|vue)$/) }.first(2).map do |f|
        base   = f["content"].presence || "# #{f['path']}\n"
        lines  = base.to_s.lines
        ours   = lines.dup
        theirs = lines.dup
        ours[0]   = "// <<< incoming (this PR)\n#{ours[0]}"   if ours[0]
        theirs[0] = "// <<< base (target branch)\n#{theirs[0]}" if theirs[0]
        { "path" => f["path"], "language" => f["language"],
          "ours" => ours.join, "theirs" => theirs.join }
      end
    end

    private

    def ai_verdict(pr)
      return nil unless pr.respond_to?(:ai_reviews)

      pr.ai_reviews.order(created_at: :desc).first&.verdict
    rescue StandardError
      nil
    end
  end
end
