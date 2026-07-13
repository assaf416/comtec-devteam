# GitHub REST API integration — reads issues for a project's repository so they
# can be mirrored into local Ticket records. Authenticates with a personal
# access token (ENV["GITHUB_TOKEN"]); unauthenticated requests still work for
# public repos but are heavily rate-limited.
#
# Mirrors the shape of GiteaService (Faraday, best-effort, logs and returns
# empty/nil on failure) so callers can treat both the same way.
class GithubService
  BASE_URL  = ENV.fetch("GITHUB_API_URL", "https://api.github.com")
  API_TOKEN = ENV.fetch("GITHUB_TOKEN", "")
  PER_PAGE  = 100
  MAX_PAGES = 20 # safety cap: up to 2000 issues per repo

  def initialize
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.request  :json
      f.response :json
      f.headers["Accept"]               = "application/vnd.github+json"
      f.headers["X-GitHub-Api-Version"] = "2022-11-28"
      f.headers["User-Agent"]           = "DevTeamHub"
      f.headers["Authorization"]        = "Bearer #{API_TOKEN}" if API_TOKEN.present?
    end
  end

  # Fetch every issue for a repo (state: "all" | "open" | "closed"), following
  # pagination. GitHub's issues endpoint also returns pull requests — those carry
  # a "pull_request" key and are filtered out here so only real issues remain.
  def issues(repo_owner:, repo_name:, state: "all")
    results = []
    (1..MAX_PAGES).each do |page|
      response = @conn.get("/repos/#{repo_owner}/#{repo_name}/issues") do |req|
        req.params["state"]    = state
        req.params["per_page"] = PER_PAGE
        req.params["page"]     = page
      end
      break unless response.success?

      batch = Array(response.body).reject { |i| i.key?("pull_request") }
      results.concat(batch)
      break if Array(response.body).size < PER_PAGE
    end
    results
  rescue Faraday::Error => e
    Rails.logger.error "GithubService#issues failed: #{e.message}"
    []
  end

  # Create an issue in the repo. Returns the created issue hash (with number and
  # html_url) or nil on failure.
  def create_issue(repo_owner:, repo_name:, title:, body: nil, labels: [])
    response = @conn.post("/repos/#{repo_owner}/#{repo_name}/issues") do |req|
      req.body = { title: title, body: body, labels: Array(labels) }.compact
    end
    response.success? ? response.body : nil
  rescue Faraday::Error => e
    Rails.logger.error "GithubService#create_issue failed: #{e.message}"
    nil
  end

  def available?
    response = @conn.get("/rate_limit")
    response.success?
  rescue Faraday::Error
    false
  end

  # ── Write operations (used to deploy edited Cucumber tests) ────────────────

  # Repo's default branch name (e.g. "main"), or nil on failure.
  def default_branch(repo_owner:, repo_name:)
    response = @conn.get("/repos/#{repo_owner}/#{repo_name}")
    response.success? ? response.body["default_branch"] : nil
  rescue Faraday::Error => e
    Rails.logger.error "GithubService#default_branch failed: #{e.message}"
    nil
  end

  # Decoded UTF-8 content of a file at path (optionally on a ref), or nil.
  def file_content(repo_owner:, repo_name:, path:, ref: nil)
    response = @conn.get("/repos/#{repo_owner}/#{repo_name}/contents/#{path}") do |req|
      req.params["ref"] = ref if ref.present?
    end
    return nil unless response.success?

    Base64.decode64(response.body["content"].to_s).force_encoding("UTF-8")
  rescue Faraday::Error => e
    Rails.logger.error "GithubService#file_content failed: #{e.message}"
    nil
  end

  # SHA the branch currently points at (for branching), or nil.
  def branch_sha(repo_owner:, repo_name:, branch:)
    response = @conn.get("/repos/#{repo_owner}/#{repo_name}/git/ref/heads/#{branch}")
    response.success? ? response.body.dig("object", "sha") : nil
  rescue Faraday::Error => e
    Rails.logger.error "GithubService#branch_sha failed: #{e.message}"
    nil
  end

  # Blob SHA of an existing file on a ref (needed to update it), or nil if new.
  def content_sha(repo_owner:, repo_name:, path:, ref:)
    response = @conn.get("/repos/#{repo_owner}/#{repo_name}/contents/#{path}") do |req|
      req.params["ref"] = ref
    end
    response.success? ? response.body["sha"] : nil
  rescue Faraday::Error
    nil
  end

  # Create a new branch pointing at from_sha. Returns true on success.
  def create_branch(repo_owner:, repo_name:, new_branch:, from_sha:)
    response = @conn.post("/repos/#{repo_owner}/#{repo_name}/git/refs") do |req|
      req.body = { ref: "refs/heads/#{new_branch}", sha: from_sha }
    end
    response.success?
  rescue Faraday::Error => e
    Rails.logger.error "GithubService#create_branch failed: #{e.message}"
    false
  end

  # Create or update a file on a branch. Pass sha to update an existing file.
  # Returns the response body (with commit info) or nil on failure.
  def put_file(repo_owner:, repo_name:, path:, content:, message:, branch:, sha: nil)
    response = @conn.put("/repos/#{repo_owner}/#{repo_name}/contents/#{path}") do |req|
      req.body = {
        message: message,
        content: Base64.strict_encode64(content.to_s),
        branch:  branch,
        sha:     sha
      }.compact
    end
    response.success? ? response.body : nil
  rescue Faraday::Error => e
    Rails.logger.error "GithubService#put_file failed: #{e.message}"
    nil
  end

  # Open a pull request. Returns the created PR hash (with html_url) or nil.
  def create_pull_request(repo_owner:, repo_name:, title:, head:, base:, body: nil)
    response = @conn.post("/repos/#{repo_owner}/#{repo_name}/pulls") do |req|
      req.body = { title: title, head: head, base: base, body: body }.compact
    end
    response.success? ? response.body : nil
  rescue Faraday::Error => e
    Rails.logger.error "GithubService#create_pull_request failed: #{e.message}"
    nil
  end

  # Parse owner/name from a repo URL like https://github.com/acme/widget(.git).
  # Returns [nil, nil] when the URL isn't a recognisable GitHub repo URL.
  def self.repo_parts(repo_url)
    return [ nil, nil ] if repo_url.blank?

    uri = URI.parse(repo_url)
    parts = uri.path.delete_prefix("/").split("/")
    owner = parts[0]
    name  = parts[1]&.delete_suffix(".git")
    [ owner.presence, name.presence ]
  rescue URI::InvalidURIError
    [ nil, nil ]
  end

  # True when the URL points at github.com (so we don't try to sync a Gitea repo).
  def self.github_url?(repo_url)
    return false if repo_url.blank?
    URI.parse(repo_url).host.to_s.end_with?("github.com")
  rescue URI::InvalidURIError
    false
  end
end
