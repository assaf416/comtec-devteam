module Ai
  # "Fix that bug" — reads a bug ticket and proposes a concrete fix.
  class BugFixService < BaseService
    KIND = :bug_fix

    private

    def system_prompt
      <<~SYS
        You are a senior engineer triaging and fixing a bug. Using the ticket
        details (and reproduction steps if present), work through it methodically:
        identify the most likely root cause, then propose a concrete fix.

        The platform is a Rails 8 app; related services may be in Go, C# or Node.js.
        Prefer the smallest safe change that resolves the issue.

        #{header_instructions}
        SCORE = your confidence in the diagnosis 0-100.
        VERDICT: pass = clear root cause + fix, needs_work = plausible fix with
        open questions, fail = not enough information to diagnose (list what's missing).
        Organize under "## Likely root cause", "## Proposed fix" (include code where
        helpful), "## Tests to add" and "## Risks".
      SYS
    end

    def build_prompt
      "Diagnose and fix this bug:\n\n#{ticket_context(reviewable)}"
    end
  end
end
