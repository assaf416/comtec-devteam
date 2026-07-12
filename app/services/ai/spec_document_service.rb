module Ai
  # Generates a **specification document** (Markdown) for a project, derived from
  # its stories. reviewable = the Project; optional input[:topic] focuses the spec
  # on a particular feature/area.
  class SpecDocumentService < BaseService
    KIND = :spec_document

    private

    def topic
      input[:topic].to_s.strip.presence
    end

    def system_prompt
      <<~SYS
        You are a senior product engineer writing a clear software specification.
        Produce a well-structured document in GitHub-flavored Markdown with these
        sections (use `##` headings):
        - Overview
        - Goals & scope
        - Functional requirements (derive from the user stories provided; group
          related ones; write testable requirements)
        - Non-functional requirements (performance, security, i18n, accessibility)
        - Architecture & data notes
        - Acceptance criteria
        - Out of scope
        - Open questions

        Base functional requirements on the stories provided. Where the input is
        thin, state reasonable assumptions explicitly. Do not add a VERDICT/SCORE line.
      SYS
    end

    def build_prompt
      project = reviewable
      stories = project.tickets.where(kind: [ :story, :meta_story ]).limit(25)
      story_lines = stories.map do |t|
        "- #{t.title}#{t.description.present? ? ": #{t.description.to_s.truncate(200)}" : ''}"
      end

      scope = topic ? "Focus the specification on: #{topic}.\n\n" : ""

      <<~TXT
        #{scope}Write a specification for the project "#{project.name}".
        Tech stack: #{project.tech_stack}
        Project description: #{project.description.to_s.truncate(400)}

        User stories to base the functional requirements on:
        #{story_lines.presence&.join("\n") || '- (no stories captured yet — infer sensible requirements from the description)'}
      TXT
    end
  end
end
