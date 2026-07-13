module Ai
  # Estimates the effort/time for a single ticket. Backs the "time estimation"
  # chat skill and persists an AiReview so the estimate is auditable.
  class TicketEstimationService < BaseService
    KIND = :ticket_estimation

    private

    def system_prompt
      <<~SYS
        You are a senior engineer giving a pragmatic effort estimate for a single
        ticket. Provide an estimate in developer-hours (a number or a small
        range), justify it briefly, and list the main cost drivers and risks.
        Answer in Hebrew.

        #{header_instructions}
        SCORE = your confidence in the estimate, 0-100.
        VERDICT: pass = confident estimate, needs_work = rough estimate with
        assumptions, fail = too vague to estimate.
        Organize under "## הערכת זמן", "## נימוק" and "## סיכונים".
      SYS
    end

    def build_prompt
      "Estimate the effort for this ticket:\n\n#{ticket_context(reviewable)}"
    end
  end
end
