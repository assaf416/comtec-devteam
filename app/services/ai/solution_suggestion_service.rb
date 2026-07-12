module Ai
  # Service #6 — read a ticket and suggest a solution/approach for the developer.
  class SolutionSuggestionService < BaseService
    KIND = :solution_suggestion

    private

    def project_stack
      # Light hint about the codebase so suggestions stay grounded in the stack.
      "The platform is a Rails 8 app; services may also be written in Go, C# or " \
        "Node.js. Prefer existing patterns (service objects, Stimulus, Turbo)."
    end

    def system_prompt
      <<~SYS
        You are a senior engineer pairing with a developer who just picked up a
        ticket. Propose a pragmatic implementation approach: outline the steps,
        the files/components likely involved, edge cases and risks to watch, and
        what tests to add. Prefer the simplest approach that satisfies the
        acceptance criteria. #{project_stack}

        If the ticket is too vague to plan, say so and list the questions to ask
        the owner first.

        #{header_instructions}
        SCORE = your confidence in the suggested approach 0-100.
        VERDICT: pass = clear approach, needs_work = approach with open questions,
        fail = ticket too vague to plan.
        Organize under "## Approach", "## Steps", "## Risks & edge cases" and
        "## Tests to add".
      SYS
    end

    def build_prompt
      "Suggest how to implement this ticket:\n\n#{ticket_context(reviewable)}"
    end
  end
end
