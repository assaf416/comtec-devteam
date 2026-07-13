module Api
  module V1
    class TicketsController < BaseController
      before_action :set_ticket, only: %i[show]

      # Tickets mirror GitHub issues and are read-only here; author/edit them on
      # GitHub, then sync (POST /projects/:id/sync_issues or `rake github:sync`).

      # GET /api/v1/tickets
      # ?status=open&project_id=1&assignee=me
      def index
        scope = Ticket.includes(:project, :assignee, :owner)

        scope = scope.where(assignee: current_api_user) if params[:assignee] == "me"
        scope = scope.where(project_id: params[:project_id]) if params[:project_id].present?
        scope = scope.where(status: params[:status])         if params[:status].present?
        scope = scope.where(priority: params[:priority])     if params[:priority].present?

        tickets = scope.order(updated_at: :desc).limit(100)
        render json: tickets.map { |t| render_ticket(t) }
      end

      # GET /api/v1/tickets/:id
      def show
        render json: render_ticket(@ticket)
      end

      private

      def set_ticket
        @ticket = Ticket.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Ticket not found" }, status: :not_found
      end
    end
  end
end
