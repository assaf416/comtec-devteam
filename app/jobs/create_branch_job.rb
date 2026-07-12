class CreateBranchJob < ApplicationJob
  queue_as :default

  def perform(ticket_id)
    ticket = Ticket.includes(:project, :assignee).find_by(id: ticket_id)
    return unless ticket && ticket.project.gitea_repo_id.present?

    branch_name = ticket.branch_name_for_ticket
    owner, repo  = ticket.project.gitea_repo_id.split("/")
    base_branch  = ticket.project.default_branch.presence || "main"

    result = GiteaService.new.create_branch(
      repo_owner: owner,
      repo_name:  repo,
      branch_name: branch_name,
      base_branch: base_branch
    )

    if result
      ticket.branches.find_or_create_by(
        name:    branch_name,
        project: ticket.project
      )
      ticket.update_column(:branch_name, branch_name)
      Rails.logger.info "Branch #{branch_name} created for ticket ##{ticket.id}"
    else
      Rails.logger.warn "Could not create branch #{branch_name} for ticket ##{ticket.id}"
    end
  end
end
