module Deploy
  # Thin HTTP wrapper around the external deploy backend (a Jarvis-style runner
  # or Gitea Actions deployment API). Configure via ENV; when it isn't reachable
  # the methods fail soft (return nil / false / []) so the UI can run in a
  # "demo / not wired up yet" mode without raising.
  #
  #   JARVIS_URL      e.g. http://jarvis.local:5000
  #   JARVIS_API_KEY  bearer token for the backend
  #   JARVIS_REGISTRY container registry host used to build image refs
  class JarvisClient
    class Error < StandardError; end

    BASE_URL = ENV.fetch("JARVIS_URL", "").freeze
    API_KEY  = ENV.fetch("JARVIS_API_KEY", "").freeze
    REGISTRY = ENV.fetch("JARVIS_REGISTRY", "registry.local").freeze
    TIMEOUT  = ENV.fetch("JARVIS_TIMEOUT", "30").to_i

    def initialize(base_url: BASE_URL, api_key: API_KEY)
      @base_url = base_url
      @api_key  = api_key
      @conn = build_connection if configured?
    end

    # True only when a backend URL is configured. Drives "demo mode" in the UI.
    def configured?
      @base_url.present?
    end

    # Best-effort health check.
    def available?
      return false unless configured?

      resp = @conn.get("/health")
      resp.success?
    rescue Faraday::Error
      false
    end

    # Image tags the backend reports as deployable for a project. Returns an
    # array of hashes: [{ "tag" =>, "commit" =>, "built_at" => }, ...].
    def available_tags(project_ref:)
      return [] unless configured?

      resp = @conn.get("/projects/#{project_ref}/images")
      return [] unless resp.success?

      Array(resp.body["images"])
    rescue Faraday::Error => e
      Rails.logger.warn "Deploy::JarvisClient#available_tags failed: #{e.message}"
      []
    end

    # Trigger a deployment. Returns the backend's response hash on success,
    # raises Deploy::JarvisClient::Error otherwise. Callers persist the result.
    def deploy(project_ref:, image_tag:, environment:, server_ip:, triggered_by: nil)
      raise Error, "Deploy backend is not configured (set JARVIS_URL)." unless configured?

      resp = @conn.post("/deploy") do |req|
        req.body = {
          project:     project_ref,
          image:       image_ref(image_tag),
          environment: environment,
          target:      server_ip,
          actor:       triggered_by
        }
      end
      raise Error, "Deploy backend responded #{resp.status}" unless resp.success?

      resp.body
    rescue Faraday::Error => e
      raise Error, "Could not reach the deploy backend at #{@base_url}: #{e.message}"
    end

    # Fully-qualified image reference for a tag, e.g. registry.local/app:1001.
    def image_ref(image_tag)
      [ REGISTRY, image_tag ].join("/")
    end

    private

    def build_connection
      Faraday.new(url: @base_url) do |f|
        f.request  :json
        f.response :json
        f.headers["Authorization"] = "Bearer #{@api_key}" if @api_key.present?
        f.options.timeout      = TIMEOUT
        f.options.open_timeout = 5
      end
    end
  end
end
