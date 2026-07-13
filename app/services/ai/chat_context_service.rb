module Ai
  # Builds the system prompt for the Chat with AI page from the current state of
  # a project: tickets, tasks, recent team messages, documents, and recent
  # code changes (PR diffs). Sizes are capped to keep the prompt manageable.
  class ChatContextService
    def initialize(project: nil)
      @project = project
    end

    def system_prompt
      <<~SYS
        You are DevTeam Hub's project assistant. Answer using the live project
        context below. Be concise and practical. When asked to produce a document
        (specification, risk management, test plan, etc.), return well-structured
        GitHub-flavored Markdown. If something isn't in the context, say so.

        ===== PROJECT CONTEXT =====
        #{context_body}
        ===== END CONTEXT =====
      SYS
    end

    def context_body
      return "No project selected." if @project.nil?

      [
        project_section,
        team_performance_section,
        tickets_section,
        documents_section,
        messages_section,
        code_section
      ].compact.join("\n\n")
    end

    private

    def project_section
      <<~TXT.strip
        Project: #{@project.name}
        Git repository: #{@project.repo_url.presence || '(not configured)'}
        Default branch: #{@project.default_branch.presence || 'main'}
        Tech stack: #{@project.tech_stack}
        Description: #{@project.description.to_s.truncate(400)}
      TXT
    end

    # Per-developer delivery + estimation metrics so the assistant can answer
    # "who is the fastest delivering developer?" and "who estimates best?".
    def team_performance_section
      done   = @project.tickets.where(status: %i[done closed]).includes(:assignee).to_a
      by_dev = done.group_by(&:assignee).reject { |dev, _| dev.nil? }
      return nil if by_dev.empty?

      rows = by_dev.map do |dev, tickets|
        with_est  = tickets.select { |t| t.dev_estimate_hours.present? && t.actual_hours_in_hours.present? }
        variances = with_est.filter_map do |t|
          est = t.dev_estimate_hours.to_f
          est.zero? ? nil : (t.actual_hours_in_hours - est).abs / est * 100
        end
        accuracy   = variances.empty? ? nil : (100 - variances.sum / variances.size).round
        avg_actual = with_est.empty? ? nil : (with_est.sum { |t| t.actual_hours_in_hours } / with_est.size).round(1)

        parts = [ "delivered #{tickets.size} tickets" ]
        parts << "avg #{avg_actual}h per ticket" if avg_actual
        parts << "estimation accuracy #{accuracy}%" if accuracy
        "- #{dev.display_name}: #{parts.join(', ')}"
      end

      "Team performance (delivered work on this project — lower avg hours per " \
        "ticket = faster; higher accuracy = better estimator):\n#{rows.join("\n")}"
    end

    def tickets_section
      tickets = @project.tickets.includes(:assignee).order(updated_at: :desc).limit(25)
      return nil if tickets.empty?

      lines = tickets.map do |t|
        "- T-#{t.id} [#{t.status}] (#{t.priority}, pts #{t.story_points || '—'}) " \
          "#{t.title.truncate(70)} — #{t.assignee&.display_name || 'unassigned'}"
      end
      "Tickets:\n#{lines.join("\n")}"
    end

    def documents_section
      docs = @project.documents.order(updated_at: :desc).limit(10)
      return nil if docs.empty?

      "Documents: #{docs.map { |d| "#{d.title} (#{d.doc_type})" }.join('; ')}"
    end

    def messages_section
      rooms = @project.try(:chat_rooms)
      return nil if rooms.blank?

      msgs = ChatMessage.where(chat_room_id: rooms.select(:id))
                        .order(created_at: :desc).limit(15).includes(:user)
      return nil if msgs.empty?

      lines = msgs.reverse.map { |m| "- #{m.user&.display_name}: #{m.body.to_s.truncate(120)}" }
      "Recent team messages:\n#{lines.join("\n")}"
    end

    def code_section
      prs = @project.pull_requests.where.not(code_changed: [ nil, "" ]).order(updated_at: :desc).limit(3)
      header = "Code lives in the project's git repository: #{@project.repo_url.presence || '(repo URL not configured)'}"
      return header if prs.empty?

      blocks = prs.map do |pr|
        "PR ##{pr.pr_number} #{pr.title}:\n```diff\n#{pr.code_changed.to_s.truncate(1500)}\n```"
      end
      "#{header}\nRecent code changes from this repository:\n#{blocks.join("\n\n")}"
    end
  end
end
