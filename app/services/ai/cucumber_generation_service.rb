module Ai
  # Writes Cucumber/Gherkin scenarios for code that was just merged. Given a diff
  # (e.g. the latest merged PR's changes) it returns Markdown containing a
  # ```gherkin .feature block. Runs on the local LLM.
  class CucumberGenerationService
    def initialize(project: nil, client: nil)
      @project = project
      @client  = client || OllamaClient.new
    end

    def call(diff:)
      @client.chat(system: system_prompt, prompt: build_prompt(diff))
    end

    private

    def system_prompt
      <<~SYS
        You are a QA engineer. Write Cucumber (Gherkin) acceptance tests that cover
        the behavior introduced by the code below. Reply with a short one-line Hebrew
        intro, then EXACTLY one fenced ```gherkin code block containing a complete
        Feature with 2-4 focused Scenarios (happy path + edge cases). Prefer
        domain-level steps over brittle UI steps. Do not invent behavior that is not
        implied by the code.
      SYS
    end

    def build_prompt(diff)
      code = diff.to_s.strip.presence || "(no code provided)"
      <<~TXT
        Project: #{@project&.name} (#{@project&.tech_stack})

        Code that was just merged into the version:
        ```
        #{code.truncate(4000)}
        ```
      TXT
    end
  end
end
