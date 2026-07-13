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

      # POST /api/v1/tickets — create a ticket (and open a GitHub issue if the
      # project is GitHub-backed).
      def create
        project = Project.find_by(id: params[:project_id])
        return render json: { error: "Project not found" }, status: :not_found unless project

        ticket = project.tickets.new(
          title:       params[:title],
          description: params[:description],
          kind:        params[:kind].presence || "story",
          priority:    params[:priority].presence || "medium",
          assignee_id: params[:assignee_id]
        )
        ticket.owner = current_api_user

        if ticket.save
          TicketGithubIssueService.new(ticket).call
          render json: render_ticket(ticket), status: :created
        else
          render json: { errors: ticket.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/tickets/:id — assign to a user and/or update the status.
      def update
        return if performed? # set_ticket already rendered not_found

        attrs = {}
        attrs[:status]      = params[:status]      if params[:status].present?
        attrs[:assignee_id] = params[:assignee_id] if params.key?(:assignee_id)

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
