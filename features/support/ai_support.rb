# ── AI / Ollama test support ──────────────────────────────────────────────────
#
# 1. Put the spec/ directory on the load path so the shared step definitions can
#    `require 'rails_helper'` (RSpec expectations, FactoryBot, etc).
# 2. Stub Ai::OllamaClient so scenarios never reach out to a real Ollama server.
#    Tests control the canned response and availability through class accessors.
#
# This file lives under features/ so it is ONLY loaded during cucumber runs —
# production code is untouched.

spec_path = Rails.root.join("spec").to_s
$LOAD_PATH.unshift(spec_path) unless $LOAD_PATH.include?(spec_path)

# The shared step file (features/step_definitions/steps.rb) does
# `require 'rails_helper'`, which in turn calls RSpec.configure. Under cucumber
# rspec-core is not auto-loaded, so load it here (before step definitions run) to
# make RSpec.configure / matchers / FactoryBot available.
require "rspec/rails"

# Enable Warden test mode so the shared steps can call `login_as(...)`.
require "warden"
Warden.test_mode!
World(Warden::Test::Helpers)
After { Warden.test_reset! }

require Rails.root.join("app/services/ai/ollama_client").to_s

module Ai
  class OllamaClient
    class << self
      attr_accessor :test_response, :test_available
    end

    DEFAULT_TEST_RESPONSE = <<~MD.freeze
      VERDICT: needs_work
      SCORE: 62

      ## Findings
      This is a stubbed AI response used in the cucumber suite.
    MD

    # Override the real network calls with deterministic, offline behaviour.
    def chat(system:, prompt:, temperature: 0.2)
      raise Ai::OllamaClient::Error, "Ollama offline (stub)" if self.class.test_available == false

      self.class.test_response || DEFAULT_TEST_RESPONSE
    end

    def generate(prompt:, temperature: 0.2)
      chat(system: "", prompt: prompt)
    end

    def available?
      self.class.test_available.nil? ? true : self.class.test_available
    end

    def models
      available? ? [ "llama3.1:8b (stub)" ] : []
    end
  end
end

# Reset the stub before every scenario.
Before do
  Ai::OllamaClient.test_response  = nil
  Ai::OllamaClient.test_available = true
end
