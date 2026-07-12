# Gitea API integration service
require "base64"

class GiteaService
  BASE_URL = ENV.fetch("GITEA_URL", "http://localhost:3001")
  API_TOKEN = ENV.fetch("GITEA_TOKEN", "")

  def initialize
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.request  :json
      f.response :json
      f.headers["Authorization"] = "token #{API_TOKEN}"
    end
  end

  # Create a branch for a ticket
  def create_branch(repo_owner:, repo_name:, branch_name:, base_branch: "main")
    response = @conn.post("/api/v1/repos/#{repo_owner}/#{repo_name}/branches") do |req|
      req.body = { new_branch_name: branch_name, old_branch_name: base_branch }
    end
    response.success? ? response.body : nil
  rescue Faraday::Error => e
    Rails.logger.error "GiteaService#create_branch failed: #{e.message}"
    nil
  end

  # Get pull requests for a repo
  def pull_requests(repo_owner:, repo_name:, state: "open")
    response = @conn.get("/api/v1/repos/#{repo_owner}/#{repo_name}/pulls", { state: state })
    response.success? ? response.body : []
  rescue Faraday::Error => e
    Rails.logger.error "GiteaService#pull_requests failed: #{e.message}"
    []
  end

  # Create or update a webhook
  def create_webhook(repo_owner:, repo_name:, target_url:, secret:)
    response = @conn.post("/api/v1/repos/#{repo_owner}/#{repo_name}/hooks") do |req|
      req.body = {
        active: true,
        config: { url: target_url, content_type: "json", secret: secret },
        events: %w[push pull_request issues],
        type: "gitea"
      }
    end
    response.success? ? response.body : nil
  rescue Faraday::Error
    nil
  end

  # Create a pull request in Gitea
  def create_pull_request(repo_owner:, repo_name:, title:, head:, base:, body: nil)
    response = @conn.post("/api/v1/repos/#{repo_owner}/#{repo_name}/pulls") do |req|
      req.body = {
        title: title,
        head: head,
        base: base,
        body: body
      }.compact
    end
    response.success? ? response.body : nil
  rescue Faraday::Error => e
    Rails.logger.error "GiteaService#create_pull_request failed: #{e.message}"
    nil
  end

  # Verify webhook HMAC signature
  def self.valid_signature?(payload, signature, secret)
    return false if signature.blank? || secret.blank?
    expected = "sha256=#{OpenSSL::HMAC.hexdigest('sha256', secret, payload)}"
    ActiveSupport::SecurityUtils.secure_compare(expected, signature)
  end

  # ── Pull Request data ──────────────────────────────────────────────

  # Fetch a single PR's metadata
  def pull_request(repo_owner:, repo_name:, pr_number:)
    response = @conn.get("/api/v1/repos/#{repo_owner}/#{repo_name}/pulls/#{pr_number}")
    response.success? ? response.body : nil
  rescue Faraday::Error => e
    Rails.logger.error "GiteaService#pull_request failed: #{e.message}"
    nil
  end

  # Fetch the unified diff for a PR
  def pull_request_diff(repo_owner:, repo_name:, pr_number:)
    response = Faraday.get(
      "#{BASE_URL}/api/v1/repos/#{repo_owner}/#{repo_name}/pulls/#{pr_number}.diff",
      {},
      { "Authorization" => "token #{API_TOKEN}", "Accept" => "text/plain" }
    )
    response.success? ? response.body : nil
  rescue Faraday::Error => e
    Rails.logger.error "GiteaService#pull_request_diff failed: #{e.message}"
    nil
  end

  # Fetch list of changed files for a PR
  def pull_request_files(repo_owner:, repo_name:, pr_number:)
    response = @conn.get("/api/v1/repos/#{repo_owner}/#{repo_name}/pulls/#{pr_number}/files")
    return [] unless response.success?
    Array(response.body).map { |f| f["filename"] }
  rescue Faraday::Error => e
    Rails.logger.error "GiteaService#pull_request_files failed: #{e.message}"
    []
  end

  # Fetch changed files with per-file stats (status + additions/deletions).
  def pull_request_file_details(repo_owner:, repo_name:, pr_number:)
    response = @conn.get("/api/v1/repos/#{repo_owner}/#{repo_name}/pulls/#{pr_number}/files")
    return [] unless response.success?
    Array(response.body).map do |f|
      {
        "filename"  => f["filename"],
        "status"    => f["status"],
        "additions" => f["additions"].to_i,
        "deletions" => f["deletions"].to_i
      }
    end
  rescue Faraday::Error => e
    Rails.logger.error "GiteaService#pull_request_file_details failed: #{e.message}"
    []
  end

  # Fetch the raw text content of a file from a repo (best-effort).
  def file_content(repo_owner:, repo_name:, path:, ref: nil)
    params = ref.present? ? { ref: ref } : {}
    response = @conn.get("/api/v1/repos/#{repo_owner}/#{repo_name}/contents/#{path}", params)
    return nil unless response.success?

    body = response.body
    return nil unless body.is_a?(Hash) && body["content"].present?
    body["encoding"] == "base64" ? Base64.decode64(body["content"]) : body["content"]
  rescue Faraday::Error => e
    Rails.logger.error "GiteaService#file_content failed: #{e.message}"
    nil
  end

  # Fetch PR review comments
  def pull_request_comments(repo_owner:, repo_name:, pr_number:)
    response = @conn.get("/api/v1/repos/#{repo_owner}/#{repo_name}/issues/#{pr_number}/comments")
    return [] unless response.success?
    Array(response.body).map do |c|
      { "user" => c.dig("user", "login"), "message" => c["body"], "created_at" => c["created_at"] }
    end
  rescue Faraday::Error => e
    Rails.logger.error "GiteaService#pull_request_comments failed: #{e.message}"
    []
  end

  # Fetch CI statuses for the PR head commit
  def commit_statuses(repo_owner:, repo_name:, sha:)
    response = @conn.get("/api/v1/repos/#{repo_owner}/#{repo_name}/statuses/#{sha}")
    response.success? ? Array(response.body) : []
  rescue Faraday::Error => e
    Rails.logger.error "GiteaService#commit_statuses failed: #{e.message}"
    []
  end

  # Parse repo owner/name from a repo_url like http://gitea.local/devteam/print-server-tdi
  def self.repo_parts(repo_url)
    return [ nil, nil ] if repo_url.blank?
    parts = URI.parse(repo_url).path.delete_prefix("/").split("/")
    [ parts[0], parts[1] ]
  rescue URI::InvalidURIError
    [ nil, nil ]
  end
end
