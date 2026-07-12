class TicketsController < ApplicationController
  before_action :set_project, only: [ :index, :new, :create ]
  before_action :set_ticket,  only: [ :show, :edit, :update, :destroy, :move_to_sprint, :update_status, :approve ]

  def index
    @tickets = @project.tickets.includes(:assignee, :sprint, :ci_runs).order(priority: :desc, created_at: :desc)
    @tickets = @tickets.where(status: params[:status]) if params[:status].present?
    @tickets = @tickets.where(assignee: current_user) if params[:mine] == "true"
    @tickets = @tickets.tagged_with(params[:tag]) if params[:tag].present?
  end

  def all
    @tickets = Ticket.includes(:assignee, :owner, :sprint, :project)
                     .order(priority: :desc, created_at: :desc)
    @tickets = @tickets.where(status: params[:status]) if params[:status].present?
    @tickets = @tickets.where(project_id: params[:project_id]) if params[:project_id].present?
    @tickets = @tickets.where(assignee_id: params[:assignee_id]) if params[:assignee_id].present?
    @tickets = @tickets.where(owner_id: params[:owner_id]) if params[:owner_id].present?
    @projects = Project.order(:name)
    @users = User.order(:name)
  end

  def mine
    @tickets = Ticket.where(assignee: current_user)
                     .includes(:assignee, :sprint, :project)
                     .order(priority: :desc, created_at: :desc)
    render :filtered_list
  end

  def late
    @tickets = Ticket.joins(:sprint)
                     .where(sprints: { end_date: ...Date.current })
                     .where.not(status: [ :done, :closed ])
                     .includes(:assignee, :sprint, :project)
                     .order(priority: :desc, created_at: :desc)
    render :filtered_list
  end

  def backlog_list
    @tickets = Ticket.where(status: :backlog)
                     .includes(:assignee, :sprint, :project)
                     .order(priority: :desc, created_at: :desc)
    render :filtered_list
  end

  def current_sprint
    sprint = Sprint.current.first
    @tickets = if sprint
                 sprint.tickets.includes(:assignee, :sprint, :project)
                       .order(priority: :desc, created_at: :desc)
    else
                 Ticket.none
    end
    render :filtered_list
  end

  def show
    @comments   = @ticket.comments.includes(:author).order(created_at: :asc)
    @ci_runs    = @ticket.ci_runs.includes(:test_results).order(created_at: :desc).limit(10)
    @branches   = @ticket.branches
    @pull_requests = @ticket.pull_requests
  end

  def new
    @ticket = @project.tickets.build
  end

  def create
    @ticket = @project.tickets.build(ticket_params)

    if @ticket.save
      TicketNotificationJob.perform_later(@ticket.id, "created") if defined?(TicketNotificationJob)
      redirect_to @ticket, notice: t("tickets.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @section = edit_section
  end

  def update
    @section = edit_section
    old_assignee_id = @ticket.assignee_id
    updated_attrs = ticket_params.to_h
    # Only stamp the estimator when the estimation fields are the ones being edited.
    updated_attrs["estimated_by_id"] = current_user.id if @section == "estimation"

    if @ticket.update(updated_attrs)
      # Auto-create branch when ticket is assigned for the first time
      if @ticket.assignee_id.present? && old_assignee_id != @ticket.assignee_id
        CreateBranchJob.perform_later(@ticket.id) if defined?(CreateBranchJob)
        TicketMailer.assigned(@ticket).deliver_later
      end
      # Notify watchers on status change
      if @ticket.saved_change_to_status?
        @ticket.watchers.each { |w| TicketMailer.status_changed(@ticket, w).deliver_later }
      end
      redirect_to @ticket, notice: t("tickets.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @ticket.destroy
    redirect_to project_tickets_path(@project), notice: t("tickets.deleted")
  end

  # Moves a ticket between the backlog, the project's current sprint, and the
  # project's next (upcoming) sprint. Triggered from the row actions dropdown.
  def move_to_sprint
    case params[:target]
    when "current"
      sprint = @project.sprints.current.first
      return redirect_after_move(alert: t("tickets.move.no_current_sprint")) unless sprint
      assign_sprint(sprint)
      redirect_after_move(notice: t("tickets.move.moved_to_current"))
    when "next"
      sprint = @project.sprints.upcoming.first
      return redirect_after_move(alert: t("tickets.move.no_next_sprint")) unless sprint
      assign_sprint(sprint)
      redirect_after_move(notice: t("tickets.move.moved_to_next"))
    when "backlog"
      @ticket.update(sprint: nil, status: :backlog)
      redirect_after_move(notice: t("tickets.move.moved_to_backlog"))
    else
      redirect_after_move(alert: t("tickets.move.invalid_target"))
    end
  end

  # Approve a ticket — marks it ready to move on from the drafting stage to
  # refinement/estimation. Triggered from the ticket page or a row action.
  def approve
    @ticket.approve! unless @ticket.approved?
    redirect_back fallback_location: ticket_path(@ticket), notice: "Ticket approved."
  end

  # Quick status change from a row actions dropdown (e.g. the project page).
  def update_status
    if Ticket.statuses.key?(params[:status]) && @ticket.update(status: params[:status])
      redirect_after_move(notice: t("tickets.status_updated", status: t("tickets.statuses.#{@ticket.status}")))
    else
      redirect_after_move(alert: t("tickets.move.invalid_target"))
    end
  end

  private

  # Assigns the ticket to a sprint, promoting it out of the backlog so it shows
  # up in the active board rather than staying hidden in the backlog filter.
  def assign_sprint(sprint)
    attrs = { sprint: sprint }
    attrs[:status] = :open if @ticket.backlog?
    @ticket.update(attrs)
  end

  def redirect_after_move(notice: nil, alert: nil)
    redirect_back fallback_location: all_tickets_path, notice: notice, alert: alert
  end

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_ticket
    @ticket  = Ticket.find(params[:id])
    @project = @ticket.project
  end

  # Which slice of the ticket form to render: "specs" (the basics) or
  # "estimation" (refinement & estimation). Keeps each form short.
  def edit_section
    %w[specs estimation].include?(params[:section]) ? params[:section] : "specs"
  end

  def ticket_params
    params.require(:ticket).permit(
      :title, :description, :status, :priority, :kind, :level,
      :how_to_reproduce, :test_plan, :actual_velocity, :sprint_id, :assignee_id, :owner_id,
      :milestone_id, :story_points, :tag_list, :pr_number, :pr_url,
      :dev_estimate_hours, :tester_estimate_hours, :actual_hours, :approved_at,
      attachments: []
    )
  end
end
