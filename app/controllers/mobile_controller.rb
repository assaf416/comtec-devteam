class MobileController < ApplicationController
  layout "mobile"
  before_action :authenticate_user!

  # ── Today ─────────────────────────────────────────────────────────────────
  def today
    today_range = Time.current.beginning_of_day..Time.current.end_of_day

    @my_active_tickets = current_user.assigned_tickets
                           .where.not(status: %i[done closed])
                           .includes(:project)
                           .order(priority: :desc, updated_at: :desc)
                           .limit(10)

    @meetings_today = Meeting
                        .joins(:meeting_attendees)
                        .where(meeting_attendees: { user_id: current_user.id })
                        .where(scheduled_at: today_range)
                        .where.not(status: :cancelled)
                        .includes(:project, :organizer)
                        .order(:scheduled_at)
                        .or(
                          Meeting.where(organizer: current_user, scheduled_at: today_range)
                                 .where.not(status: :cancelled)
                                 .includes(:project, :organizer)
                                 .order(:scheduled_at)
                        )
                        .distinct

    @next_meeting = @meetings_today.find { |m| m.scheduled_at > Time.current }

    @my_ci_runs_today = CiRun.where(triggered_by: current_user, created_at: today_range)
                               .includes(:project)
                               .order(created_at: :desc)
                               .limit(5)

    @my_failing_builds = CiRun.where(triggered_by: current_user, status: :failed)
                                .includes(:project)
                                .order(created_at: :desc)
                                .limit(3)

    @my_deployments_today = Deployment.where(deployed_by: current_user, created_at: today_range)
                                        .includes(:project)
                                        .order(created_at: :desc)
                                        .limit(5)

    my_project_ids = current_user.assigned_tickets.select(:project_id).distinct
    @recent_prs = PullRequest.where(project_id: my_project_ids, status: :open)
                               .order(updated_at: :desc)
                               .limit(5)

    @summary = {
      active_tickets:  @my_active_tickets.size,
      meetings_today:  @meetings_today.size,
      ci_runs_today:   @my_ci_runs_today.size,
      failing_builds:  @my_failing_builds.size,
      deploys_today:   @my_deployments_today.size,
      open_prs:        @recent_prs.size
    }
  end

  # ── Messages ──────────────────────────────────────────────────────────────
  def messages
    @chat_rooms = ChatRoom.includes(:chat_messages)
                          .order(updated_at: :desc)
  end

  # ── Meetings ──────────────────────────────────────────────────────────────
  def meetings
    @upcoming = Meeting
                  .joins(:meeting_attendees)
                  .where(meeting_attendees: { user_id: current_user.id })
                  .where("scheduled_at >= ?", Time.current)
                  .where.not(status: :cancelled)
                  .includes(:project, :organizer)
                  .order(:scheduled_at)
                  .or(
                    Meeting.where(organizer: current_user)
                           .where("scheduled_at >= ?", Time.current)
                           .where.not(status: :cancelled)
                           .includes(:project, :organizer)
                           .order(:scheduled_at)
                  )
                  .distinct
                  .limit(20)

    @past = Meeting
              .joins(:meeting_attendees)
              .where(meeting_attendees: { user_id: current_user.id })
              .where("scheduled_at < ?", Time.current)
              .includes(:project, :organizer)
              .order(scheduled_at: :desc)
              .or(
                Meeting.where(organizer: current_user)
                       .where("scheduled_at < ?", Time.current)
                       .includes(:project, :organizer)
                       .order(scheduled_at: :desc)
              )
              .distinct
              .limit(10)
  end

  # ── Projects ──────────────────────────────────────────────────────────────
  def projects
    @projects = Project.includes(:tickets)
                       .order(updated_at: :desc)
  end

  # ── Tickets ───────────────────────────────────────────────────────────────
  def tickets
    scope = current_user.assigned_tickets.includes(:project, :assignee, :owner)
    scope = Ticket.includes(:project, :assignee, :owner) if scope.none?

    @open = scope.where.not(status: %i[done closed])
                 .order(priority: :desc, updated_at: :desc).limit(25)
    @done = scope.where(status: %i[done closed]).order(updated_at: :desc).limit(10)
  end

  # ── Video Calls ───────────────────────────────────────────────────────────
  def video_calls
    @upcoming_video = Meeting
                        .joins(:meeting_attendees)
                        .where(meeting_attendees: { user_id: current_user.id })
                        .where("scheduled_at >= ?", Time.current)
                        .where.not(status: :cancelled)
                        .includes(:project, :organizer)
                        .order(:scheduled_at)
                        .or(
                          Meeting.where(organizer: current_user)
                                 .where("scheduled_at >= ?", Time.current)
                                 .where.not(status: :cancelled)
                                 .includes(:project, :organizer)
                                 .order(:scheduled_at)
                        )
                        .distinct
                        .limit(10)

    @active_video = @upcoming_video.select { |m| m.status.to_s == "in_progress" }
  end

  # ── Project show ────────────────────────────────────────────────────────────
  def project
    @project = Project.find(params[:id])
    @tickets = @project.tickets.includes(:assignee, :owner)
                       .order(priority: :desc, updated_at: :desc).limit(20)
    @pull_requests = @project.pull_requests.order(updated_at: :desc).limit(10)
    @members  = @project.members.order(:name)
    @notes    = @project.documents.order(updated_at: :desc).limit(10)
    # Project has no direct comments; surface the latest discussion from its tickets.
    @comments = Comment.where(commentable_type: "Ticket", commentable_id: @project.ticket_ids)
                       .includes(:author).order(created_at: :desc).limit(10)
  end

  # ── Ticket show ─────────────────────────────────────────────────────────────
  def ticket
    @ticket  = Ticket.find(params[:id])
    @project = @ticket.project
    @tasks   = @ticket.tasks.order(:created_at)
    @pull_requests = @ticket.pull_requests.order(updated_at: :desc)
    @comments = @ticket.comments.includes(:author).order(created_at: :desc)
    @members  = [@ticket.assignee, @ticket.owner, *@ticket.watchers].compact.uniq
    @notes    = @project.documents.order(updated_at: :desc).limit(5)
  end
end
