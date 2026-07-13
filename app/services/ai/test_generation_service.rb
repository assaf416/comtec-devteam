module Ai
  # Generates Cucumber (.feature) tests in Hebrew for a ticket, so the team can
  # attach acceptance tests to it via the AI agent. Persists an AiReview whose
  # body is the generated Gherkin.
  class TestGenerationService < BaseService
    KIND = :test_generation

    private

    def system_prompt
      <<~SYS
        You are a QA engineer writing acceptance tests for a ticket. Produce
        Cucumber (Gherkin) scenarios **in Hebrew**: start the feature block with
        `# language: he` and use the Hebrew keywords (תכונה / רקע / תרחיש /
        בהינתן / כאשר / אז / וגם). Cover the happy path plus key edge cases and
        error handling implied by the ticket. Keep scenarios concise and
        behaviour-focused.

        #{header_instructions}
        SCORE = how confidently the ticket can be tested as written, 0-100.
        VERDICT: pass = testable now, needs_work = testable with assumptions,
        fail = too vague to test.
        Put the tests inside a single ```gherkin code block under "## בדיקות".
      SYS
    end

    def build_prompt
      "Write Cucumber acceptance tests (in Hebrew) for this ticket:\n\n#{ticket_context(reviewable)}"
    end
  end
end
