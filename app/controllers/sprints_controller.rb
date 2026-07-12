class SprintsController < ApplicationController
  before_action :set_project, only: %i[index new create]
  before_action :set_sprint,  only: %i[show edit update destroy dashboard activate]

  def index
    @sprints = @project.sprints.order(start_date: :desc)
    @active_sprint    = @sprints.active.first
    @planning_sprints = @sprints.planning
    @done_sprints     = @sprints.completed
  end

  def show
    @tickets = @sprint.tickets.includes(:assignee, :owner, :tasks).order(:status, :priority).to_a

    # Top-tile totals
    @done_count    = @tickets.count { |t| %w[done closed].include?(t.status) }
    @progress      = @sprint.progress_percent
    @bug_count     = @tickets.count { |t| %w[bug_fix hotfix].include?(t.kind) }

    # Tickets tabs: open / completed / needs estimation
    @tab = params[:tab].presence_in(%w[open completed needs_estimation]) || "open"
    not_closed = @tickets.reject { |t| %w[done closed].include?(t.status) }
    @tab_tickets = case @tab
    when "completed"        then @tickets.select { |t| %w[done closed].include?(t.status) }
    when "needs_estimation" then not_closed.select { |t| t.story_points.blank? || t.dev_estimate_hours.blank? }
    else                         not_closed
    end
    @tab_counts = {
      "open"            => not_closed.size,
      "completed"       => @tickets.size - not_closed.size,
      "needs_estimation" => not_closed.count { |t| t.story_points.blank? || t.dev_estimate_hours.blank? }
    }

    @meetings      = @sprint.meetings.order(:scheduled_at)
    @pull_requests = @sprint.pull_requests.includes(:ticket).order(created_at: :desc)
    @comments      = @sprint.comments.includes(:author).order(:created_at)
    @comment       = Comment.new
    @documents     = @sprint.documents.includes(:author).order(updated_at: :desc)
  end

  # Analytical dashboard summarising and analysing a single sprint.
  # The "analyse" half is the live AI sprint analysis embedded in the view.
  def dashboard
    tickets         = @sprint.tickets.includes(:assignee)
    @total_tickets  = tickets.count
    @done_tickets   = tickets.where(status: [ :done, :closed ]).count
    @in_progress    = tickets.where(status: [ :in_progress, :in_review, :testing ]).count
    @not_started    = tickets.where(status: [ :backlog, :open ]).count
    @blocked        = tickets.where(status: :blocked).count
    @progress_percent = @sprint.progress_percent

    @status_counts  = tickets.group(:status).count
    @points_total   = tickets.sum(:story_points)
    @points_done    = tickets.where(status: [ :done, :closed ]).sum(:story_points)

    # Task-based progress & estimation (from the cached ticket rollups).
    @task_estimation_total = tickets.sum(:total_tasks_estimation)
    @tasks_total           = tickets.sum(:tasks_count)
    @tasks_done            = tickets.sum(:completed_tasks_count)
    @task_progress_percent = @tasks_total.zero? ? 0 : (@tasks_done * 100.0 / @tasks_total).round

    @workload = tickets.where.not(status: [ :done, :closed ])
                       .where.not(assignee_id: nil)
                       .joins(:assignee).group("users.name").count
                       .sort_by { |_, v| -v }

    @insights = build_sprint_insights
  end

  def new
    @sprint = @project.sprints.build(
      start_date: Date.today,
      end_date:   Date.today + 14
    )
  end

  def create
    @sprint = @project.sprints.build(sprint_params)
    if @sprint.save
      redirect_to @sprint, notice: "Sprint created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # Set this sprint as the project's current (active) one — closes the previous.
  def activate
    @sprint.make_current!
    redirect_to @sprint, notice: "\"#{@sprint.name}\" is now the current sprint for #{@project.name}."
  end

  def edit; end

  def update
    if @sprint.update(sprint_params)
      redirect_to @sprint, notice: "Sprint updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project = @sprint.project
    @sprint.destroy
    redirect_to project_sprints_path(@project), notice: "Sprint deleted."
  end

  private

  # Rule-based highlights for the sprint dashboard (deterministic, no LLM).
  def build_sprint_insights
    insights = []
    insights << { level: "info", text: "#{@progress_percent}% done with #{@sprint.days_remaining} day(s) remaining." }
    if @tasks_total.positive?
      insights << { level: "info", text: "Task progress: #{@task_progress_percent}% (#{@tasks_done}/#{@tasks_total} tasks) · #{@task_estimation_total}h estimated." }
    end
    insights << { level: "danger",  text: "#{@blocked} ticket(s) are blocked." } if @blocked.positive?

    if @sprint.active? && @total_tickets.positive?
      remaining_share = (@total_tickets - @done_tickets) * 100.0 / @total_tickets
      total_days      = [ @sprint.duration_days, 1 ].max
      time_used_share = (total_days - @sprint.days_remaining) * 100.0 / total_days
      if remaining_share > (100 - time_used_share) + 15
        insights << { level: "warning", text: "Behind pace — #{remaining_share.round}% of tickets remain with #{(100 - time_used_share).round}% of the time gone." }
      else
        insights << { level: "success", text: "On pace to complete the sprint." }
      end
    end

    insights << { level: "warning", text: "#{@not_started} ticket(s) not started yet." } if @not_started.positive? && @sprint.active?
    insights
  end

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_sprint
    @sprint  = Sprint.find(params[:id])
    @project = @sprint.project
  end

  def sprint_params
    params.require(:sprint).permit(:name, :start_date, :end_date, :status, :goals, :velocity,
                                   :things_to_improve, :things_that_went_right)
  end
end
