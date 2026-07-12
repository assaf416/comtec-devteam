module Api
  module V1
    class TicketsController < BaseController
      before_action :set_ticket, only: %i[show update]

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

      # POST /api/v1/tickets
      def create
        attrs = params.require(:ticket).permit(
          :project_id, :title, :description, :status, :priority,
          :kind, :level, :how_to_reproduce, :assignee_id,
          :owner_id, :dev_estimate_hours, :tester_estimate_hours, :actual_hours
        )

        ticket = Ticket.new(attrs)
        ticket.owner ||= current_api_user

        if ticket.save
          render json: render_ticket(ticket), status: :created
        else
          render json: { errors: ticket.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/tickets/:id
      def update
        allowed = %w[
          title description status priority kind level how_to_reproduce test_plan
          assignee_id owner_id sprint_id milestone_id pr_number pr_url branch_name
          story_points actual_velocity dev_estimate_hours tester_estimate_hours actual_hours
        ]
        attrs   = params.require(:ticket).permit(*allowed)

        if @ticket.update(attrs)
          render json: render_ticket(@ticket)
        else
          render json: { errors: @ticket.errors.full_messages }, status: :unprocessable_entity
        end
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
