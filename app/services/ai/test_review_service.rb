module Ai
  # Service #3 — review Cucumber tests. Suggests changes/optimizations and points
  # out missing scenarios. Pass the feature file text via input[:feature].
  class TestReviewService < BaseService
    KIND = :test_review

    private

    def system_prompt
      <<~SYS
        You are a QA automation expert specialising in Cucumber/Gherkin BDD.
        Review the provided feature file(s) for:
        - Clarity: scenarios read as behaviour, not implementation
        - Structure: good use of Background, Scenario Outline + Examples, tags
        - Determinism: no flaky/order-dependent steps, explicit waits over sleeps
        - Coverage gaps: missing edge cases, negative paths, permissions, i18n,
          boundary values, error handling
        - Step reuse and redundancy

        #{header_instructions}
        Organize your reply under "## Issues", "## Optimizations" and
        "## Missing Scenarios" (write the missing ones as ready-to-use Gherkin).
        Use VERDICT: pass only when coverage is solid; needs_work when there are
        meaningful gaps; fail when the tests are largely inadequate.
      SYS
    end

    def build_prompt
      ctx = reviewable.is_a?(Ticket) ? "Related ticket — #{ticket_context(reviewable)}\n\n" : ""
      feature = input[:feature].presence || "(no feature text supplied)"
      "#{ctx}Review these Cucumber tests:\n\n```gherkin\n#{feature}\n```"
    end
  end
end
