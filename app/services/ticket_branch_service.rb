# Handles branch creation on Gitea and user notification when a ticket is assigned.
class TicketBranchService
  def initialize(ticket)
    @ticket  = ticket
    @project = ticket.project
  end

  def call
    branch = generate_branch_name
    persist_branch_name(branch)
    try_create_gitea_branch(branch)
    create_assignment_notification(branch)
  end

  private

  def generate_branch_name
    @ticket.branch_name_for_ticket
  end

  # kept for backwards compat — delegates to model

  def persist_branch_name(branch)
    # update_column bypasses callbacks so we don't recurse
    @ticket.update_column(:branch_name, branch)
  end

  def try_create_gitea_branch(branch)
    return unless @project.repo_url.present?

    uri   = URI.parse(@project.repo_url)
    parts = uri.path.split("/").reject(&:blank?)
    return unless parts.size >= 2

    GiteaService.new.create_branch(
      repo_owner:  parts[0],
      repo_name:   parts[1],
      branch_name: branch,
      base_branch: @project.default_branch.presence || "main"
    )
  rescue URI::InvalidURIError, Faraday::Error => e
    Rails.logger.warn "TicketBranchService: could not create Gitea branch — #{e.message}"
    nil
  end

  def create_assignment_notification(branch)
    base      = @project.default_branch.presence || "main"
    git_fetch = "git fetch origin"
    git_cmd   = "git checkout -b #{branch} origin/#{base}"

    TicketBranchNotification.create!(
      recipient: @ticket.assignee,
      params: {
        "message"      => "You've been assigned to \"#{@ticket.title}\" — " \
                          "branch #{branch} is ready",
        "url"          => "/projects/#{@ticket.project_id}/tickets/#{@ticket.id}",
        "ticket_id"    => @ticket.id,
        "ticket_title" => @ticket.title,
        "project_name" => @project.name,
        "branch_name"  => branch,
        "git_command"  => "#{git_fetch} && #{git_cmd}"
      }
    )
  rescue => e
    Rails.logger.error "TicketBranchService#create_assignment_notification: #{e.message}"
  end
end
