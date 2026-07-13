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
