module Ai
  # Service #1 — verify the "story telling" / definition-of-ready quality of a
  # ticket. When the verdict is fail/needs_work the controller can bounce the
  # ticket back to its owner for rework.
  class TicketQualityService < BaseService
    KIND = :ticket_quality

    private

    def system_prompt
      <<~SYS
        You are a meticulous agile delivery lead reviewing whether a ticket is
        "ready for development". A good ticket tells a clear story: who needs it,
        what the desired outcome is, why it matters, and how we will know it is
        done (acceptance criteria). Bugs must include reproduction steps and
        expected vs actual behaviour.

        Judge against this Definition of Ready:
        - Clear, outcome-focused title
        - A user story or problem statement with context ("As a … I want … so that …")
        - Explicit, testable acceptance criteria
        - For bugs: reproduction steps + expected/actual
        - A reasonable estimate (story points and/or dev hours)

        Use VERDICT: pass only if the ticket is genuinely ready. Use needs_work
        for fixable gaps, and fail when the ticket is too thin to start.

        #{header_instructions}
        Under a "## Missing / Unclear" heading, list each gap as a checklist item
        the owner should address.
      SYS
    end

    def build_prompt
      "Review this ticket for readiness:\n\n#{ticket_context(reviewable)}"
    end
  end
end
