module Ai
  # Thin REST client for a self-hosted Ollama server (e.g. the on-prem Mac mini
  # running the local LLM). Mirrors the Faraday-based style of GiteaService /
  # JenkinsService so there is a single, consistent integration pattern.
  #
  # Ollama exposes a simple HTTP API:
  #   POST /api/chat      { model, messages:[{role,content}], stream:false }
  #   POST /api/generate  { model, prompt, stream:false }
  #   GET  /api/tags      → list of locally-installed models
  #
  # No extra gem is required — Faraday (already in the Gemfile for Gitea/Jenkins)
  # is enough. We deliberately use stream:false so the whole completion comes back
  # in one JSON body, which is simplest to persist into an AiReview.
  class OllamaClient
    class Error < StandardError; end

    BASE_URL      = ENV.fetch("OLLAMA_URL", "http://localhost:11434")
    DEFAULT_MODEL = ENV.fetch("OLLAMA_MODEL", "llama3.1")
    # Local models can be slow on first token — give generations plenty of room.
    READ_TIMEOUT  = ENV.fetch("OLLAMA_TIMEOUT", "300").to_i

    attr_reader :model

    def initialize(model: DEFAULT_MODEL, base_url: BASE_URL)
      @model = model
      @conn = Faraday.new(url: base_url) do |f|
        f.request  :json
        f.response :json
        f.options.timeout      = READ_TIMEOUT
        f.options.open_timeout = 10
      end
    end

    # Send a system + user prompt and return the assistant's text reply.
    def chat(system:, prompt:, temperature: 0.2)
      response = @conn.post("/api/chat") do |req|
        req.body = {
          model: @model,
          stream: false,
          options: { temperature: temperature },
          messages: [
            { role: "system", content: system },
            { role: "user",   content: prompt }
          ]
        }
      end
      raise Error, "Ollama responded #{response.status}" unless response.success?

      response.body.dig("message", "content").to_s
    rescue Faraday::Error => e
      raise Error, "Could not reach Ollama at #{BASE_URL}: #{e.message}"
    end

    # Multi-turn conversation. `messages` is an array of { role:, content: }
    # (roles: system / user / assistant) — used by the Chat with AI page.
    def converse(messages:, temperature: 0.3)
      response = @conn.post("/api/chat") do |req|
        req.body = { model: @model, stream: false, options: { temperature: temperature }, messages: messages }
      end
      raise Error, "Ollama responded #{response.status}" unless response.success?

      response.body.dig("message", "content").to_s
    rescue Faraday::Error => e
      raise Error, "Could not reach Ollama at #{BASE_URL}: #{e.message}"
    end

    # Single-prompt completion (no system role).
    def generate(prompt:, temperature: 0.2)
      response = @conn.post("/api/generate") do |req|
        req.body = { model: @model, prompt: prompt, stream: false,
                     options: { temperature: temperature } }
      end
      raise Error, "Ollama responded #{response.status}" unless response.success?

      response.body["response"].to_s
    rescue Faraday::Error => e
      raise Error, "Could not reach Ollama at #{BASE_URL}: #{e.message}"
    end

    # Liveness/health probe used by the AI dashboard.
    def available?
      response = @conn.get("/api/tags")
      response.success?
    rescue Faraday::Error
      false
    end

    # Names of models installed on the Ollama host.
    def models
      response = @conn.get("/api/tags")
      return [] unless response.success?

      Array(response.body["models"]).map { |m| m["name"] }
    rescue Faraday::Error
      []
    end
  end
end
