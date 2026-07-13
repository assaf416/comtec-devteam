# Opens a GitHub issue for a freshly-created ticket and records the issue number
# and URL back onto the ticket. Best-effort: if the project isn't backed by a
# GitHub repo (or the API fails) it simply returns nil and the ticket is
# unaffected. Called synchronously from TicketsController#create.
class TicketGithubIssueService
  # Test seam (test env only): when set, #call uses it instead of calling GitHub.
  cattr_accessor :test_result

  def initialize(ticket, github: GithubService.new)
    @ticket = ticket
    @gh     = github
  end

  def call
    issue = resolve_issue
    return nil unless issue.present?

    @ticket.update(
      github_issue_number: issue["number"],
      github_url:          issue["html_url"]
    )
    issue
  rescue => e
    Rails.logger.error "TicketGithubIssueService failed: #{e.message}"
    nil
  end

  private

  def resolve_issue
    return self.class.test_result if Rails.env.test? && self.class.test_result
    return nil unless github_repo?

    owner, repo = GithubService.repo_parts(@ticket.project.repo_url)
    return nil unless owner && repo

    @gh.create_issue(
      repo_owner: owner, repo_name: repo,
      title: @ticket.title, body: @ticket.description.to_s,
      labels: [ @ticket.kind ].compact
    )
  end

  def github_repo?
    url = @ticket.project&.repo_url
    url.present? && GithubService.github_url?(url)
  end
end
