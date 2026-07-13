module Tools
  # AI Agent — drives the local Ollama LLM (on the on-prem Mac mini) for the
  # team's AI-assisted workflows. Each service action contacts Ollama, persists an
  # AiReview, and surfaces the result in the UI.
  class AiController < ApplicationController
    # The service endpoints are normal authenticated form/Turbo posts.

    # ── Dashboards ──────────────────────────────────────────────────────────
    def index
      client          = Ai::OllamaClient.new
      @ollama_online  = client.available?
      @ollama_models  = @ollama_online ? client.models : []
      @ollama_model   = Ai::OllamaClient::DEFAULT_MODEL
      @ollama_url     = Ai::OllamaClient::BASE_URL

      @recent_reviews = AiReview.recent.limit(25)
      @counts         = AiReview.group(:kind).count
      @failures       = AiReview.where(status: :failed).recent.limit(5)
    end

    def reviews
      @reviews = AiReview.code_reviews.recent.page(params[:page])
    end

    def test_reviews
      @reviews = AiReview.test_reviews.recent.page(params[:page])
    end

    def show
      @review = AiReview.find(params[:id])
    end

    # ── Service #1: ticket story-telling / readiness ──────────────────────────
    def ticket_quality
      ticket = Ticket.find(params[:ticket_id])
      review = Ai::TicketQualityService.new(reviewable: ticket, user: current_user).call

      if review.status_completed? && review.verdict != "pass"
        bounce_ticket_to_owner(ticket, review)
        notice = "AI flagged T-#{ticket.id} as #{review.verdict.humanize}. " +
                 (ticket.owner ? "Reassigned to #{ticket.owner.display_name}." : "")
      else
        notice = review.status_failed? ? ai_error(review) : "Ticket passed the AI readiness check."
      end

      redirect_to tools_ai_review_path(review), notice: notice
    end

    # ── Service #2: code review (Go / Ruby / C# / Node) ───────────────────────
    def code_review
      ticket = Ticket.find_by(id: params[:ticket_id])
      review = Ai::CodeReviewService.new(
        reviewable: ticket, user: current_user,
        diff: params[:diff], language: params[:language]
      ).call
      redirect_to tools_ai_review_path(review), notice: result_notice(review)
    end

    # ── Generate Cucumber tests (Hebrew) for a ticket ─────────────────────────
    def generate_tests
      ticket = Ticket.find(params[:ticket_id])
      review = Ai::TestGenerationService.new(reviewable: ticket, user: current_user).call
      redirect_to tools_ai_review_path(review), notice: result_notice(review)
    end

    # ── Service #3: cucumber test review ──────────────────────────────────────
    def test_review
      ticket = Ticket.find_by(id: params[:ticket_id])
      review = Ai::TestReviewService.new(
        reviewable: ticket, user: current_user, feature: params[:feature]
      ).call
      redirect_to tools_ai_review_path(review), notice: result_notice(review)
    end

    # ── Service #4: estimation accuracy (project) ─────────────────────────────
    def estimation_analysis
      subject = Project.find(params[:project_id])
      review  = Ai::EstimationAnalysisService.new(reviewable: subject, user: current_user).call
      redirect_to tools_ai_review_path(review), notice: result_notice(review)
    end

    # ── Service #6: suggest a solution for a ticket ───────────────────────────
    def solution_suggestion
      ticket = Ticket.find(params[:ticket_id])
      review = Ai::SolutionSuggestionService.new(reviewable: ticket, user: current_user).call
      redirect_to tools_ai_review_path(review), notice: result_notice(review)
    end

    # ── Service #7: "Fix that bug" — diagnose + propose a fix ──────────────────
    def fix_bug
      ticket = Ticket.find(params[:ticket_id])
      review = Ai::BugFixService.new(reviewable: ticket, user: current_user).call
      redirect_to tools_ai_review_path(review), notice: result_notice(review)
    end

    # ── Service #8: break a story into estimated tasks (creates Task records) ──
    def generate_tasks
      ticket = Ticket.find(params[:ticket_id])
      review = Ai::TaskBreakdownService.new(reviewable: ticket, user: current_user).call

      created = 0
      if review.status_completed?
        Ai::TaskBreakdownService.parse_tasks(review.body).each do |attrs|
          ticket.tasks.create(
            description: attrs[:description],
            estimation:  attrs[:estimation],
            user:        ticket.assignee || ticket.owner
          )
          created += 1
        end
      end

      notice = if review.status_failed?
        ai_error(review)
      elsif created.zero?
        "AI ran but produced no parseable tasks — see the full report."
      else
        "AI generated #{created} task(s) with estimations."
      end
      redirect_to ticket_path(ticket, anchor: "tasks"), notice: notice
    end

    private

    # Verify story telling failed → send the ticket back to its owner for rework.
    def bounce_ticket_to_owner(ticket, review)
      return if ticket.owner_id.blank?

      ticket.update(assignee_id: ticket.owner_id, status: :open)
      Comment.create!(
        commentable: ticket,
        author:      current_user,
        body:        "🤖 **AI readiness check: #{review.verdict.humanize}**\n\n" \
                     "Reassigned to the owner for rework.\n\n#{review.summary}"
      )
    rescue => e
      Rails.logger.error "AiController#bounce_ticket_to_owner: #{e.message}"
    end

    def result_notice(review)
      review.status_failed? ? ai_error(review) : "AI review completed."
    end

    def ai_error(review)
      "AI review could not complete: #{review.error_message}"
    end
  end
end
