class TicketsController < ApplicationController
  before_action :set_project, only: [ :index ]
  before_action :set_ticket,  only: [ :show ]

  # Tickets are a read-only mirror of GitHub issues (synced via
  # projects#sync_issues). They are not authored in-app; edit them on GitHub.

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

  def show
    @comments   = @ticket.comments.includes(:author).order(created_at: :asc)
    @ci_runs    = @ticket.ci_runs.includes(:test_results).order(created_at: :desc).limit(10)
    @branches   = @ticket.branches
    @pull_requests = @ticket.pull_requests
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_ticket
    @ticket  = Ticket.find(params[:id])
    @project = @ticket.project
  end
end
