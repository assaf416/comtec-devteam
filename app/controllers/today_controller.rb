class TodayController < ApplicationController
  def index
    today     = Time.current.beginning_of_day..Time.current.end_of_day
    yesterday = 1.day.ago.beginning_of_day..1.day.ago.end_of_day

    # ── Active tickets assigned to me ────────────────────────────────────────
    @my_active_tickets = current_user.assigned_tickets
                           .where.not(status: %i[done closed])
                           .includes(:project)
                           .order(priority: :desc, updated_at: :desc)

    # Tickets I touched today (updated, commented, or status changed)
    @tickets_updated_today = current_user.assigned_tickets
                               .where(updated_at: today)
                               .includes(:project)
                               .order(updated_at: :desc)

    # ── Documents ─────────────────────────────────────────────────────────────
    # Documents created or updated today on any project I'm active in
    my_project_ids = current_user.assigned_tickets.select(:project_id).distinct
    @documents_today = Document.where(project_id: my_project_ids)
                         .where(updated_at: today)
                         .includes(:project, :author)
                         .order(updated_at: :desc)
                         .limit(10)

    # Files I most recently opened (last 5), newest first
    @recent_attachments = AttachmentView.where(user: current_user)
                            .includes(attachment: [ :project, { file_attachment: :blob } ])
                            .order(viewed_at: :desc)
                            .limit(5)
                            .map(&:attachment)
                            .compact

    # ── CI Runs I triggered today ─────────────────────────────────────────────
    @my_ci_runs_today = CiRun.where(triggered_by: current_user, started_at: today)
                          .or(CiRun.where(triggered_by: current_user, created_at: today))
                          .includes(:project, :ticket, :test_results)
                          .order(created_at: :desc)

    # Latest still-failing build per project (my runs)
    @my_failing_builds = CiRun.where(triggered_by: current_user, status: :failed)
                           .includes(:project)
                           .order(created_at: :desc)
                           .first(5)

    # ── Deployments I ran today ───────────────────────────────────────────────
    @my_deployments_today = Deployment.where(deployed_by: current_user, created_at: today)
                              .includes(:project)
                              .order(created_at: :desc)

    # ── Meetings today ────────────────────────────────────────────────────────
    @meetings_today = Meeting.joins(:meeting_attendees)
                       .where(meeting_attendees: { user_id: current_user.id })
                       .where(scheduled_at: today)
                       .where.not(status: :cancelled)
                       .includes(:project, :organizer)
                       .order(:scheduled_at)
                       .or(
                         Meeting.where(organizer: current_user, scheduled_at: today)
                                .where.not(status: :cancelled)
                                .includes(:project, :organizer)
                                .order(:scheduled_at)
                       )
                       .distinct

    @next_meeting = @meetings_today.find { |m| m.scheduled_at > Time.current }

    # ── Milestones ────────────────────────────────────────────────────────────
    project_ids = current_user.assigned_tickets.select(:project_id).distinct
    @milestones_due_today    = Milestone.where(project_id: project_ids, due_date: Date.today)
                                 .includes(:project)
    @milestones_overdue      = Milestone.where(project_id: project_ids)
                                 .where("due_date < ?", Date.today)
                                 .where.not(status: :completed)
                                 .includes(:project)
                                 .order(:due_date)

    # ── CI Quick Links ────────────────────────────────────────────────────────
    # Projects where I've triggered CI runs, with their Jenkins/Gitea URLs
    @ci_projects = Project.joins(:ci_runs)
                    .where(ci_runs: { triggered_by_id: current_user.id })
                    .includes(:ci_runs)
                    .distinct
                    .order(:name)

    @jenkins_url = ENV.fetch("JENKINS_URL", "http://localhost:8080")
    @gitea_url   = ENV.fetch("GITEA_URL",   "http://localhost:3000")

    # ── Review queue: PRs awaiting review + my own open PRs ─────────────────────
    @review_queue = PullRequest.where(status: %i[open review])
                               .includes(:project, :ticket)
                               .order(updated_at: :desc).limit(10)
    @my_open_prs  = PullRequest.where(status: %i[open review], author: current_user.display_name)
                               .includes(:project).order(updated_at: :desc).limit(10)

    # ── Summary counters ──────────────────────────────────────────────────────
    @summary = {
      active_tickets:    @my_active_tickets.count,
      meetings_today:    @meetings_today.size,
      ci_runs_today:     @my_ci_runs_today.size,
      deployments_today: @my_deployments_today.size,
      docs_changed:      @documents_today.size,
      recent_files:      @recent_attachments.size,
      milestones_today:  @milestones_due_today.size + @milestones_overdue.size
    }
  end
end
