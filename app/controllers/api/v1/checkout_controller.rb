module Api
  module V1
    # POST /api/v1/checkout  { ticket_id: 42 }
    # Responds with the branch name that should be checked out locally.
    # The actual git commands are run by the CLI — the API just ensures
    # the branch name is canonical and the ticket status is updated.
    class CheckoutController < BaseController
      def create
        ticket = Ticket.find(params[:ticket_id])

        branch = ticket.branch_name_for_ticket

        # Auto-assign and set in_progress when the current user checks out
        ticket.update(assignee: current_api_user, status: :in_progress) if ticket.assignee.nil? || params[:assign]

        render json: {
          branch:     branch,
          ticket_id:  ticket.id,
          title:      ticket.title,
          repo_url:   ticket.project.repo_url,
          base:       ticket.project.default_branch || "main",
          clone_ssh:  repo_to_ssh(ticket.project.repo_url)
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Ticket not found" }, status: :not_found
      end

      private

      def repo_to_ssh(url)
        return nil if url.blank?
        uri = URI.parse(url)
        "git@#{uri.host}:#{uri.path.delete_prefix('/')}.git"
      rescue URI::InvalidURIError
        nil
      end
    end
  end
end
