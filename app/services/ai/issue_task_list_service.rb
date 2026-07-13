module Ai
  # Reads a chunk of source material (a pasted file / spec / notes) and proposes a
  # list of actionable tasks to open as GitHub issues. Returns an array of
  # { "title" => ..., "body" => ... } hashes. Nothing is created here — the chat
  # asks the user to approve before opening the issues. Runs on the local LLM.
  class IssueTaskListService
    def initialize(project: nil, client: nil)
      @project = project
      @client  = client || OllamaClient.new
    end

    def call(source:)
      raw = @client.chat(system: system_prompt, prompt: build_prompt(source))
      parse(raw)
    end

    # Parses lines of the form "TITLE :: BODY" (one task per line) into hashes.
    def parse(raw)
      raw.to_s.lines.filter_map do |line|
        line = line.strip.sub(/\A[-*\d.)\s]+/, "")
        next if line.blank?
        next unless line.include?("::")

        title, body = line.split("::", 2).map(&:strip)
        next if title.blank?
        { "title" => title.truncate(120), "body" => body.to_s }
      end
    end

    private

    def system_prompt
      <<~SYS
        You break down source material (a spec, notes, or a file) into a concise list
        of actionable engineering tasks suitable for GitHub issues. Output ONLY the
        tasks, one per line, each formatted EXACTLY as:
        TITLE :: one or two sentence description
        No numbering, no headings, no extra prose. Aim for 3-10 well-scoped tasks.
      SYS
    end

    def build_prompt(source)
      <<~TXT
        Project: #{@project&.name} (#{@project&.tech_stack})

        Break the following into GitHub-issue tasks:
        #{source.to_s.truncate(4000)}
      TXT
    end
  end
end
