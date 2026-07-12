module Ai
  # Service #5 — analyse sprint status based on ticket progress. Rendered live on
  # the sprint page via a lazy Turbo Frame.
  class SprintAnalysisService < BaseService
    KIND = :sprint_analysis

    private

    def sprint
      reviewable
    end

    def status_breakdown
      sprint.tickets.group(:status).count
    end

    def snapshot
      tickets = sprint.tickets.includes(:assignee)
      lines = tickets.map do |t|
        "- T-#{t.id} [#{t.status}] (#{t.priority}, pts: #{t.story_points || '—'}) " \
          "#{t.title.truncate(60)} — #{t.assignee&.display_name || 'unassigned'}"
      end
      <<~TXT
        Sprint: #{sprint.name}
        Window: #{sprint.start_date} → #{sprint.end_date} (#{sprint.duration_days} days, #{sprint.days_remaining} remaining)
        Status: #{sprint.status} | Done: #{sprint.progress_percent}%
        Goals: #{sprint.goals.presence || '(none stated)'}
        Status counts: #{status_breakdown.map { |k, v| "#{k}=#{v}" }.join(', ')}

        Tickets:
        #{lines.join("\n")}
      TXT
    end

    def system_prompt
      <<~SYS
        You are an agile coach giving a concise, honest read on a sprint mid-flight.
        Using the ticket snapshot, assess:
        - Are we on track to meet the goals before the end date?
        - Risks and blockers (e.g. too much WIP, work stuck in review, unstarted
          high-priority items, work-remaining vs days-remaining)
        - Workload balance across assignees
        - The single most important thing the team should do next

        Be brief and specific — this renders live on the sprint page.

        #{header_instructions}
        SCORE = sprint health 0-100. VERDICT: pass = on track, needs_work = at
        risk, fail = will not complete without intervention.
        Organize under "## Health", "## Risks" and "## Recommended next step".
      SYS
    end

    def build_prompt
      "Assess this sprint's status:\n\n#{snapshot}"
    end
  end
end
