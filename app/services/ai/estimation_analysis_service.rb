module Ai
  # Service #4 — track developers' estimation accuracy: estimated vs actual
  # delivery time. Works on a Project (anything that responds to #tickets). The
  # heavy lifting (the data) is computed in Ruby; the LLM turns it into insight
  # and coaching.
  class EstimationAnalysisService < BaseService
    KIND = :estimation_analysis

    private

    def tickets
      scope = reviewable.respond_to?(:tickets) ? reviewable.tickets : Ticket.none
      scope.includes(:assignee).select do |t|
        t.dev_estimate_hours.present? && t.actual_hours_in_hours.present?
      end
    end

    def rows
      @rows ||= tickets.map do |t|
        est = t.dev_estimate_hours.to_f
        act = t.actual_hours_in_hours.to_f
        variance = est.zero? ? nil : ((act - est) / est * 100).round
        {
          id: t.id, title: t.title,
          assignee: t.assignee&.display_name || "—",
          est: est, act: act, variance: variance
        }
      end
    end

    def data_table
      header = "| Ticket | Assignee | Est (h) | Actual (h) | Variance % |\n" \
               "|--------|----------|---------|------------|------------|"
      body = rows.map do |r|
        "| T-#{r[:id]} #{r[:title].truncate(40)} | #{r[:assignee]} | " \
          "#{r[:est]} | #{r[:act]} | #{r[:variance].nil? ? '—' : "#{r[:variance]}%"} |"
      end.join("\n")
      [ header, body ].join("\n")
    end

    def system_prompt
      <<~SYS
        You are a delivery analyst. You are given a table of completed tickets with
        their estimated vs actual hours. Analyse estimation accuracy:
        - Overall bias: does the team systematically under- or over-estimate?
        - Per-developer patterns (who is consistently off, and in which direction)
        - Which ticket types/complexity correlate with the biggest variance
        - Concrete, kind, actionable coaching to improve future estimates

        #{header_instructions}
        SCORE = an accuracy score 0-100 (100 = estimates match actuals perfectly).
        VERDICT: pass if estimates are reliable, needs_work if there is notable
        drift, fail if estimation is largely unreliable.
        Organize under "## Overall", "## By Developer" and "## Recommendations".
      SYS
    end

    def build_prompt
      if rows.empty?
        return "There are no completed tickets with both an estimate and actual " \
               "hours for #{reviewable_label}. Report that estimation data is " \
               "insufficient and recommend capturing actual hours on completion."
      end

      "Estimation data for #{reviewable_label}:\n\n#{data_table}\n\n" \
        "Analyse the team's estimation accuracy."
    end

    def reviewable_label
      case reviewable
      when Project then "project \"#{reviewable.name}\""
      else "the selected work"
      end
    end
  end
end
