module Ai
  # Base class for every AI-agent service.
  #
  # Lifecycle of #call:
  #   1. create an AiReview in :running state (so the UI can show it live)
  #   2. send system_prompt + build_prompt to the local LLM via OllamaClient
  #   3. parse the reply for a machine VERDICT / SCORE header + a markdown body
  #   4. persist the result (or the error) back onto the AiReview
  #
  # Subclasses override: KIND, #system_prompt, #build_prompt.
  # They may override #parse_verdict / #parse_score for custom extraction.
  class BaseService
    KIND = nil

    attr_reader :reviewable, :user, :client, :input

    def initialize(reviewable: nil, user: nil, client: nil, model: nil, **input)
      @reviewable = reviewable
      @user       = user
      @client     = client || OllamaClient.new(model: model || OllamaClient::DEFAULT_MODEL)
      @input      = input
    end

    # Runs the service and returns the persisted AiReview (completed or failed).
    def call
      review = AiReview.create!(
        kind:       self.class::KIND,
        status:     :running,
        reviewable: reviewable,
        user:       user,
        llm_model:  client.model,
        prompt:     build_prompt
      )

      started = monotonic
      raw     = client.chat(system: system_prompt, prompt: review.prompt)

      review.update!(
        status:      :completed,
        body:        raw,
        summary:     extract_summary(raw),
        verdict:     parse_verdict(raw),
        score:       parse_score(raw),
        duration_ms: elapsed_ms(started)
      )
      review
    rescue OllamaClient::Error, StandardError => e
      Rails.logger.error "#{self.class.name} failed: #{e.message}"
      review&.update(
        status:        :failed,
        error_message: e.message,
        duration_ms:   (started ? elapsed_ms(started) : nil)
      )
      # If create! itself failed, persist a minimal failed record so the caller
      # always gets a non-nil AiReview to redirect to.
      review ||= AiReview.create(
        kind:          self.class::KIND,
        status:        :failed,
        reviewable:    reviewable,
        user:          user,
        error_message: e.message
      )
      review
    end

    private

    # ── Overridable hooks ──────────────────────────────────────────────────
    def system_prompt
      raise NotImplementedError
    end

    def build_prompt
      raise NotImplementedError
    end

    # We ask models to emit a leading "VERDICT: pass|needs_work|fail" line.
    def parse_verdict(text)
      m = text.match(/VERDICT:\s*(pass|needs_work|fail)/i)
      m && m[1].downcase
    end

    # ...and an optional "SCORE: <0-100>" line.
    def parse_score(text)
      m = text.match(/SCORE:\s*(\d{1,3})/i)
      return nil unless m
      [ [ m[1].to_i, 0 ].max, 100 ].min
    end

    def extract_summary(text)
      line = text.to_s.lines.map(&:strip).find do |l|
        l.present? && !l.match?(/\A(VERDICT|SCORE):/i) && !l.start_with?("#")
      end
      (line || text.to_s.strip).truncate(280)
    end

    # ── Prompt helpers shared across services ───────────────────────────────
    def header_instructions
      <<~TXT
        Begin your reply with two header lines exactly in this format:
        VERDICT: pass | needs_work | fail
        SCORE: <an integer 0-100>
        Then write your detailed findings in GitHub-flavored Markdown.
      TXT
    end

    def ticket_context(ticket)
      <<~TXT
        Ticket T-#{ticket.id}: #{ticket.title}
        Type: #{ticket.kind} | Priority: #{ticket.priority} | Status: #{ticket.status} | Complexity: #{ticket.level}
        Story points: #{ticket.story_points || "—"} | Dev estimate (h): #{ticket.dev_estimate_hours || "—"}
        Owner: #{ticket.owner&.display_name || "—"} | Assignee: #{ticket.assignee&.display_name || "—"}

        Description:
        #{ticket.description.presence || "(none)"}

        How to reproduce:
        #{ticket.how_to_reproduce.presence || "(n/a)"}

        Test plan:
        #{ticket.test_plan.presence || "(none)"}
      TXT
    end

    def monotonic
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def elapsed_ms(started)
      ((monotonic - started) * 1000).round
    end
  end
end
