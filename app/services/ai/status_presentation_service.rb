module Ai
  # Generates a project **status presentation** (Markdown slides) from the
  # project's live metrics. reviewable = the Project.
  class StatusPresentationService < BaseService
    KIND = :status_presentation

    private

    def system_prompt
      <<~SYS
        You are a delivery lead preparing a concise status presentation for
        stakeholders. Produce a slide-style document in GitHub-flavored Markdown:
        each slide is a `## ` heading followed by 3–6 short bullet points.

        Include these slides in order:
        1. Title & one-line summary of where the project stands
        2. Delivery progress & key metrics (tickets, tasks, estimates, CI)
        3. Sprint status
        4. Risks & blockers
        5. Recommended next steps

        Base everything strictly on the data provided — do not invent facts.
        Keep it crisp and presentation-ready. Do not add a VERDICT/SCORE line.
      SYS
    end

    def build_prompt
      "Create a status presentation for this project:\n\n#{project_snapshot}"
    end

    def project_snapshot
      project = reviewable
      tickets = project.tickets
      total   = tickets.count
      done    = tickets.where(status: [ :done, :closed ]).count
      active  = project.sprints.active.first
      ci      = project.ci_runs.where(created_at: 7.days.ago..)
      ci_rate = ci.count.zero? ? "n/a" : "#{(ci.passed.count * 100.0 / ci.count).round}%"

      milestones = project.milestones.order(:due_date).map do |m|
        "- #{m.name} (#{m.status}, due #{m.due_date})"
      end

      <<~TXT
        Project: #{project.name}
        Tech stack: #{project.tech_stack}
        Description: #{project.description.to_s.truncate(300)}

        Tickets: #{total} total, #{done} done (#{total.zero? ? 0 : (done * 100.0 / total).round}%)
        By status: #{tickets.group(:status).count.map { |k, v| "#{k}=#{v}" }.join(', ')}
        Tasks: #{tickets.sum(:completed_tasks_count)}/#{tickets.sum(:tasks_count)} done,
          #{tickets.sum(:total_tasks_estimation)}h total estimated
        Open pull requests: #{project.pull_requests.where(status: :open).count}
        CI pass rate (7d): #{ci_rate}
        Deployments (30d): #{project.deployments.where(created_at: 30.days.ago..).count}

        Active sprint: #{active ? "#{active.name} — #{active.progress_percent}% done, #{active.days_remaining} days left" : 'none'}

        Milestones:
        #{milestones.presence&.join("\n") || '- none'}
      TXT
    end
  end
end
