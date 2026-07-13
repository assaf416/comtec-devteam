module Ai
  # Generates a diagram (flowchart / ERD / UML) as a Mermaid code block from a
  # natural-language request + light project context. Returns Markdown (a fenced
  # ```mermaid block) — the chat renders it inline. Runs on the local LLM.
  class DiagramService
    def initialize(project: nil, client: nil)
      @project = project
      @client  = client || OllamaClient.new
    end

    # `kind` is inferred from the request text by the caller, or passed explicitly.
    def call(request:, kind: :flow)
      @client.chat(system: system_prompt(kind), prompt: build_prompt(request))
    end

    private

    def system_prompt(kind)
      target = case kind.to_sym
      when :erd then "an entity-relationship diagram (Mermaid `erDiagram`)"
      when :uml then "a UML class diagram (Mermaid `classDiagram`)"
      else           "a flowchart (Mermaid `flowchart TD`)"
      end

      <<~SYS
        You are a software architect. Produce #{target} that answers the request.
        Reply with EXACTLY one fenced ```mermaid code block containing valid Mermaid
        syntax, followed by a single short caption line in Hebrew. Do not add any
        other prose. Base the diagram on the project context; do not invent
        unrelated entities.
      SYS
    end

    def build_prompt(request)
      <<~TXT
        Project: #{@project&.name} (#{@project&.tech_stack})
        Description: #{@project&.description.to_s.truncate(300)}

        Request: #{request}
      TXT
    end
  end
end
