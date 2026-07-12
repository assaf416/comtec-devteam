class ProjectsController < ApplicationController
  before_action :set_project, only: [ :show, :edit, :update, :destroy, :dashboard, :report, :ci_dashboard, :calendar_events ]

  def index
    @projects = Project.order(:name)
  end

  def show
    ticket_ids = @project.tickets.select(:id)
    @recent_comments = Comment
                         .includes(:author, :commentable)
                         .where(commentable_type: "Ticket", commentable_id: ticket_ids)
                         .order(created_at: :desc)
                         .limit(8)
    @recent_ci_runs     = @project.ci_runs.includes(:triggered_by).order(created_at: :desc).limit(5)
    @recent_deployments = @project.deployments.includes(:deployed_by).order(created_at: :desc).limit(5)
    @open_pull_requests = @project.pull_requests.where(status: :open).order(updated_at: :desc).limit(5)
    @recent_documents   = @project.documents.order(updated_at: :desc).limit(6)

    # Tickets panel — filterable between open, completed, and awaiting estimation.
    not_closed = @project.tickets.where.not(status: [ :done, :closed ])
    @ticket_counts = {
      open:             not_closed.count,
      completed:        @project.tickets.where(status: [ :done, :closed ]).count,
      needs_estimation: not_closed.where(dev_estimate_hours: nil).count
    }
    @ticket_filter = params[:ticket_filter].presence_in(%w[open completed needs_estimation]) || "open"
    scope = case @ticket_filter
    when "completed"        then @project.tickets.where(status: [ :done, :closed ])
    when "needs_estimation" then not_closed.where(dev_estimate_hours: nil)
    else                         not_closed
    end
    @panel_tickets = scope.includes(:assignee).order(updated_at: :desc).limit(15)
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params)
    if @project.save
      redirect_to @project, notice: "Project created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: "Project updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_path, notice: "Project deleted."
  end

  # Analytical dashboard summarising and analysing a single project.
  def dashboard
    tickets        = @project.tickets
    not_closed     = tickets.where.not(status: [ :done, :closed ])
    @total_tickets = tickets.count
    @done_tickets  = tickets.where(status: [ :done, :closed ]).count
    @open_tickets  = not_closed.count
    @blocked       = tickets.where(status: :blocked).count
    @needs_estimation = not_closed.where(dev_estimate_hours: nil).count
    @progress_percent = @total_tickets.zero? ? 0 : (@done_tickets * 100.0 / @total_tickets).round

    @status_counts   = tickets.group(:status).count
    @priority_counts = not_closed.group(:priority).count

    @active_sprint = @project.sprints.active.first
    @open_prs      = @project.pull_requests.where(status: :open).count
    @deploys_30    = @project.deployments.where(created_at: 30.days.ago..).count

    ci_window  = @project.ci_runs.where(created_at: 7.days.ago..)
    @ci_total  = ci_window.count
    @ci_passed = ci_window.passed.count
    @ci_pass_rate = @ci_total.zero? ? nil : (@ci_passed * 100.0 / @ci_total).round

    # Task-based progress & estimation (from the cached ticket rollups).
    @task_estimation_total = tickets.sum(:total_tasks_estimation)
    @tasks_total           = tickets.sum(:tasks_count)
    @tasks_done            = tickets.sum(:completed_tasks_count)
    @task_progress_percent = @tasks_total.zero? ? 0 : (@tasks_done * 100.0 / @tasks_total).round

    # Open-work distribution across the team.
    @workload = not_closed.where.not(assignee_id: nil)
                          .joins(:assignee).group("users.name").count
                          .sort_by { |_, v| -v }

    # Estimation accuracy across completed tickets that have both values.
    completed = tickets.where(status: [ :done, :closed ]).includes(:assignee)
    rows = completed.select { |t| t.dev_estimate_hours.present? && t.actual_hours_in_hours.present? }
    @estimation = estimation_summary(rows)

    @insights = build_project_insights
  end

  def report
    @sprint_stats = @project.sprints.includes(:tickets)
    @test_summary = @project.ci_runs.includes(:test_results)
  end

  def ci_dashboard
    @ci_runs = @project.ci_runs.includes(:triggered_by, :test_results, :ticket)
                        .order(created_at: :desc).limit(100)
    render "ci_runs/index"
  end

  # GET /projects/:id/calendar_events.json
  def calendar_events
    range_start = params[:start]&.to_datetime
    range_end   = params[:end]&.to_datetime
    events = []

    # Meetings
    meetings = @project.meetings
    meetings = meetings.where(scheduled_at: range_start..range_end) if range_start && range_end
    meetings.each do |m|
      duration = (m.duration_minutes || 60).minutes
      events << {
        id:    "meeting-#{m.id}",
        title: m.title,
        start: m.scheduled_at&.iso8601,
        end:   m.scheduled_at ? (m.scheduled_at + duration).iso8601 : nil,
        url:   meeting_path(m),
        color: "#4a90d9",
        extendedProps: { type: "meeting" }
      }
    end

    # Milestones
    milestones = @project.milestones
    milestones = milestones.where(due_date: range_start..range_end) if range_start && range_end
    milestones.each do |ms|
      events << {
        id:    "milestone-#{ms.id}",
        title: "🏁 #{ms.name}",
        start: ms.due_date&.iso8601,
        allDay: true,
        url:   project_path(@project),
        color: "#e84545",
        extendedProps: { type: "milestone" }
      }
    end

    # Sprints
    @project.sprints.each do |s|
      next unless s.start_date.present? && s.end_date.present?
      next if range_start && s.end_date < range_start.to_date
      next if range_end   && s.start_date > range_end.to_date

      events << {
        id:    "sprint-#{s.id}",
        title: "⚡ #{s.name}",
        start: s.start_date.iso8601,
        end:   (s.end_date + 1.day).iso8601,
        allDay: true,
        url:   sprint_path(s),
        color: "#38c96d",
        display: "background",
        extendedProps: { type: "sprint" }
      }
    end

    render json: events
  end

  private

  # Summarise estimated-vs-actual hours for a set of completed tickets.
  def estimation_summary(rows)
    return { count: 0 } if rows.empty?

    variances = rows.map do |t|
      est = t.dev_estimate_hours.to_f
      est.zero? ? nil : ((t.actual_hours_in_hours.to_f - est) / est * 100)
    end.compact

    avg = variances.empty? ? 0 : (variances.sum / variances.size).round
    {
      count:        rows.size,
      avg_variance: avg, # +ve = took longer than estimated
      over:         variances.count { |v| v > 10 },
      under:        variances.count { |v| v < -10 },
      accuracy:     [ 100 - variances.map(&:abs).then { |a| a.empty? ? 0 : (a.sum / a.size) }, 0 ].max.round
    }
  end

  # Rule-based highlights — deterministic, always available (no LLM needed).
  def build_project_insights
    insights = []
    insights << { level: "success", text: "Project is #{@progress_percent}% complete (#{@done_tickets}/#{@total_tickets} tickets done)." }
    if @tasks_total.positive?
      insights << { level: "info", text: "Task progress: #{@task_progress_percent}% (#{@tasks_done}/#{@tasks_total} tasks) · #{@task_estimation_total}h estimated across all tasks." }
    end
    insights << { level: "danger",  text: "#{@blocked} ticket(s) are blocked and need attention." } if @blocked.positive?
    insights << { level: "warning", text: "#{@needs_estimation} open ticket(s) have no dev estimate." } if @needs_estimation.positive?
    insights << { level: "info",    text: "No active sprint — schedule one to keep work moving." } if @active_sprint.nil?

    if @ci_pass_rate
      level = @ci_pass_rate >= 90 ? "success" : (@ci_pass_rate >= 70 ? "warning" : "danger")
      insights << { level: level, text: "CI pass rate is #{@ci_pass_rate}% over the last 7 days." }
    end

    if @estimation[:count].positive?
      v = @estimation[:avg_variance]
      if v > 15
        insights << { level: "warning", text: "Team tends to underestimate — completed work took ~#{v}% longer than estimated." }
      elsif v < -15
        insights << { level: "info", text: "Team tends to overestimate — completed work finished ~#{v.abs}% faster than estimated." }
      else
        insights << { level: "success", text: "Estimates are reliable (avg variance #{v}%)." }
      end
    end

    insights
  end

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :repo_url, :tech_stack, :gitea_repo_id, :default_branch, :active)
  end
end
