class WebhooksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  # POST /webhooks/gitea
  def gitea
    signature = request.headers["X-Gitea-Signature"] || request.headers["X-Hub-Signature-256"]
    secret    = ENV.fetch("GITEA_WEBHOOK_SECRET", "")

    unless GiteaService.valid_signature?(request.raw_post, signature, secret)
      head :unauthorized and return
    end

    payload = JSON.parse(request.raw_post) rescue {}
    event   = request.headers["X-Gitea-Event"] || request.headers["X-GitHub-Event"]

    case event
    when "push"
      handle_gitea_push(payload)
    when "pull_request"
      handle_gitea_pr(payload)
    when "issues", "issue"
      handle_gitea_issue(payload)
    end

    head :ok
  rescue JSON::ParserError
    head :bad_request
  end

  # POST /webhooks/jenkins
  def jenkins
    secret = ENV.fetch("JENKINS_WEBHOOK_SECRET", "")
    token  = request.headers["X-Jenkins-Token"]
    # Reject when no secret is configured — otherwise an empty token would
    # match an empty secret and leave the webhook open to anyone.
    if secret.blank? || !ActiveSupport::SecurityUtils.secure_compare(token.to_s, secret)
      head :unauthorized and return
    end

    payload = JSON.parse(request.raw_post) rescue {}
    handle_jenkins_build(payload)
    head :ok
  rescue JSON::ParserError
    head :bad_request
  end

  private

  def handle_gitea_push(payload)
    repo_id    = "#{payload.dig('repository', 'owner', 'login')}/#{payload.dig('repository', 'name')}"
    branch     = payload["ref"]&.sub("refs/heads/", "")
    commit_sha = payload.dig("after")

    project = Project.find_by(gitea_repo_id: repo_id)
    return unless project

    # Try to find ticket from branch name
    if (m = branch&.match(/ticket\/(\d+)/))
      ticket = project.tickets.find_by(id: m[1])
    end

    ci_run = CiRun.create!(
      project:     project,
      ticket:      ticket,
      build_number: "push-#{commit_sha&.first(8)}",
      status:       :running,
      branch_name:  branch,
      commit_sha:   commit_sha,
      started_at:   Time.current
    )

    Rails.logger.info "Gitea push → CiRun ##{ci_run.id} for #{project.name}/#{branch}"
  end

  def handle_gitea_pr(payload)
    action  = payload["action"]
    pr_data = payload["pull_request"]
    return unless pr_data

    repo_id = "#{payload.dig('repository', 'owner', 'login')}/#{payload.dig('repository', 'name')}"
    project = Project.find_by(gitea_repo_id: repo_id)
    return unless project

    pr = PullRequest.find_or_initialize_by(project: project, pr_number: pr_data["number"])
    pr.title     = pr_data["title"]
    pr.gitea_url = pr_data["html_url"]
    pr.author    = pr_data.dig("user", "login")
    pr.status    = case action
    when "opened"  then :open
    when "closed"  then pr_data["merged"] ? :merged : :closed
    else :review
    end
    pr.merged_at = pr_data["merged_at"] if pr_data["merged"]
    pr.save
  end

  def handle_gitea_issue(payload)
    # Map Gitea issues to tickets if needed
  end

  def handle_jenkins_build(payload)
    build       = payload["build"] || {}
    job_name    = payload.dig("name") || payload.dig("build", "full_url", "job")
    build_number = build["number"]&.to_s
    return if job_name.blank?

    # Case-insensitive match that works on both SQLite and PostgreSQL
    # (ILIKE is PostgreSQL-only and raises on SQLite).
    project = Project.where("LOWER(tech_stack) LIKE ?", "%#{job_name.downcase}%").first
    return unless project

    status = case build["phase"]
    when "STARTED"   then :running
    when "COMPLETED" then (build["status"] == "SUCCESS" ? :passed : :failed)
    when "FINALIZED" then (build["status"] == "SUCCESS" ? :passed : :failed)
    else :pending
    end

    ci_run = CiRun.find_or_initialize_by(project: project, build_number: build_number)
    ci_run.assign_attributes(
      status:      status,
      started_at:  Time.current,
      finished_at: (status.to_s.in?(%w[passed failed cancelled]) ? Time.current : nil),
      log_url:     build["full_url"]
    )
    ci_run.save

    # Activity record for CI outcome
    if status.to_s.in?(%w[passed failed]) && ci_run.persisted?
      system_user = User.find_by(role: :admin) || User.first
      if system_user
        Activity.create(
          project:     project,
          user:        system_user,
          event_type:  status == :passed ? :ci_passed : :ci_failed,
          description: "CI build ##{build_number} #{status} via Jenkins",
          metadata:    { job: job_name, build_number: build_number, url: build["full_url"] }
        )
      end
    end

    # Notify if failed
    if ci_run.failed? && ci_run.ticket
      TicketNotificationJob.perform_later(ci_run.ticket_id, "ci_failed")
    end
  end

  # POST /webhooks/exception — APM exception ingestion
  # Expected headers: X-APM-Key: <APM_WEBHOOK_SECRET>
  # Expected JSON body: { project_id:, message:, exception_class:, backtrace:, url:, ... }
  def exception
    secret = ENV.fetch("APM_WEBHOOK_SECRET", nil)
    if secret.present? && request.headers["X-APM-Key"] != secret
      head :unauthorized and return
    end

    payload = JSON.parse(request.body.read)
    project = Project.find_by(id: payload["project_id"])
    return head :unprocessable_entity unless project

    system_user = User.find_by(role: :admin) || User.first
    return head :unprocessable_entity unless system_user

    Activity.create!(
      project:     project,
      user:        system_user,
      event_type:  :exception_raised,
      description: payload["message"].presence || payload["exception_class"] || "Exception raised",
      metadata:    payload.slice("exception_class", "url", "environment", "app_version")
                          .merge("backtrace_head" => Array(payload["backtrace"]).first(5).join("\n"))
    )

    head :created
  rescue JSON::ParserError
    head :bad_request
  end
end
