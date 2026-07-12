module Ai
  # Service #2 — review a code diff for correctness, lint compliance and language
  # best-practice across the team's stack (Go / Ruby / C# / Node).
  #
  # Pass the diff/patch text via input[:diff]; optionally input[:language] to
  # focus the lint guidance.
  class CodeReviewService < BaseService
    KIND = :code_review

    LINTERS = {
      "go"     => "gofmt, go vet, golangci-lint; idiomatic error handling, no naked returns, context usage",
      "ruby"   => "RuboCop (rails-omakase), frozen string literals, service objects, N+1 queries",
      "csharp" => "dotnet format, Roslyn analyzers, async/await correctness, IDisposable, nullable refs",
      "node"   => "ESLint + Prettier, async/await over callbacks, no unhandled promise rejections, input validation"
    }.freeze

    private

    def language
      input[:language].to_s.downcase.presence
    end

    def system_prompt
      lint_focus = if language && LINTERS[language]
        "Focus on #{language.upcase}: #{LINTERS[language]}."
      else
        "Detect the language(s) automatically. Apply the right lint rules:\n" +
          LINTERS.map { |k, v| "- #{k.upcase}: #{v}" }.join("\n")
      end

      <<~SYS
        You are a senior polyglot code reviewer for a team working in Go, Ruby,
        C# and Node.js. Review the provided diff for: correctness bugs, security
        issues, performance problems, error handling, readability, and adherence
        to language idioms and lint rules. #{lint_focus}

        Be specific: reference the changed lines, explain WHY, and give a concrete
        fix. Do not invent code that is not in the diff.

        #{header_instructions}
        Organize findings under "## Blocking", "## Suggestions" and
        "## Lint / Style". Use VERDICT: fail if there is a blocking bug or security
        issue, needs_work for non-blocking improvements, pass if it is clean.
      SYS
    end

    def build_prompt
      ctx = reviewable.is_a?(Ticket) ? "Context — #{ticket_context(reviewable)}\n\n" : ""
      diff = input[:diff].presence || "(no diff supplied)"
      "#{ctx}Review the following changes:\n\n```diff\n#{diff}\n```"
    end
  end
end
