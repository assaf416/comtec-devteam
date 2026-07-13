class TicketsController < ApplicationController
  before_action :set_project, only: [ :index, :new, :create ]
  before_action :set_ticket,  only: [ :show, :estimate ]

  def index
    @tickets = @project.tickets.includes(:assignee, :ci_runs).order(priority: :desc, created_at: :desc)
    @tickets = @tickets.where(status: params[:status]) if params[:status].present?
    @tickets = @tickets.where(assignee: current_user) if params[:mine] == "true"
    @tickets = @tickets.tagged_with(params[:tag]) if params[:tag].present?
  end

  def all
    @tickets = Ticket.includes(:assignee, :owner, :project)
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
                     .includes(:assignee, :project)
                     .order(priority: :desc, created_at: :desc)
    render :filtered_list
  end

  # "Late" = open work past its milestone due date.
  def late
    @tickets = Ticket.joins(:milestone)
                     .where(milestones: { due_date: ...Date.current })
                     .where.not(status: [ :done, :closed ])
                     .includes(:assignee, :project, :milestone)
                     .order(priority: :desc, created_at: :desc)
    render :filtered_list
  end

  def backlog_list
    @tickets = Ticket.where(status: :backlog)
                     .includes(:assignee, :project)
                     .order(priority: :desc, created_at: :desc)
    render :filtered_list
  end

  def new
    @ticket = @project.tickets.new
  end

  # Create a ticket from the project screen, then open a GitHub issue for it and
  # ask its assigned developer to estimate the effort.
  def create
    @ticket = @project.tickets.new(ticket_params)
    @ticket.owner = current_user

    if @ticket.save
      issue = TicketGithubIssueService.new(@ticket).call
      request_estimate_from_assignee(@ticket)
      notice = "Ticket created."
      notice += " Opened GitHub issue ##{@ticket.github_issue_number}." if issue.present?
      redirect_to ticket_path(@ticket), notice: notice
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @comments   = @ticket.comments.includes(:author).order(created_at: :asc)
    @ci_runs    = @ticket.ci_runs.includes(:test_results).order(created_at: :desc).limit(10)
    @branches   = @ticket.branches
    @pull_requests = @ticket.pull_requests
  end

  # The assigned developer records their time estimate for the ticket.
  def estimate
    @ticket.update(dev_estimate_hours: params[:dev_estimate_hours], estimated_by: current_user)
    redirect_to ticket_path(@ticket), notice: "Estimate saved."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def ticket_params
    params.require(:ticket).permit(:title, :description, :kind, :priority, :level,
                                   :assignee_id, :how_to_reproduce)
  end

  # Notify the assigned developer that the ticket needs their time estimate.
  def request_estimate_from_assignee(ticket)
    return if ticket.assignee.blank?

    Notification.create!(
      recipient: ticket.assignee,
      message:   "נא לתת הערכת זמן לטיקט T-#{ticket.id}: #{ticket.title}",
      params:    { "url" => ticket_path(ticket) }
    )
  rescue => e
    Rails.logger.warn "request_estimate_from_assignee failed: #{e.message}"
  end

  def set_ticket
    @ticket  = Ticket.find(params[:id])
    @project = @ticket.project
  end
end
