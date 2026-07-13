# Mirrors a project's GitHub issues into local Ticket records — GitHub is the
# source of truth for ticket data. Idempotent: tickets are keyed by
# (project_id, github_issue_number), so re-running updates in place rather than
# duplicating.
#
# Usage:
#   GithubIssueSyncService.new(project).call                 # upsert issues
#   GithubIssueSyncService.new(project, replace: true).call  # wipe local, then import
#
# Returns a result hash: { imported:, updated:, removed:, skipped:, error: }.
class GithubIssueSyncService
  Result = Struct.new(:imported, :updated, :removed, :skipped, :error, keyword_init: true) do
    def ok? = error.nil?
    def total = imported.to_i + updated.to_i
  end

  # Label (downcased) → ticket kind. First match wins; default is :story.
  KIND_BY_LABEL = {
    "bug"        => :bug_fix,
    "bugfix"     => :bug_fix,
    "defect"     => :bug_fix,
    "hotfix"     => :hotfix,
    "spike"      => :spike,
    "research"   => :spike,
    "epic"       => :meta_story,
    "meta"       => :meta_story
  }.freeze

  # Label (downcased) → priority.
  PRIORITY_BY_LABEL = {
    "critical"        => :critical,
    "priority:critical" => :critical,
    "high"            => :high,
    "priority:high"   => :high,
    "low"             => :low,
    "priority:low"    => :low
  }.freeze

  def initialize(project, client: GithubService.new, replace: false)
    @project = project
    @client  = client
    @replace = replace
  end

  def call
    owner, repo = GithubService.repo_parts(@project.repo_url)
    unless owner && repo && GithubService.github_url?(@project.repo_url)
      return Result.new(imported: 0, updated: 0, removed: 0, skipped: 0,
                        error: "Project #{@project.name} has no GitHub repo_url (got #{@project.repo_url.inspect}).")
    end

    issues = @client.issues(repo_owner: owner, repo_name: repo, state: "all")
    imported = updated = skipped = removed = 0

    ActiveRecord::Base.transaction do
      removed = purge_local_tickets! if @replace

      issues.each do |issue|
        number = issue["number"]
        next (skipped += 1) if number.blank?

        ticket = @project.tickets.find_or_initialize_by(github_issue_number: number)
        was_new = ticket.new_record?
        apply_attributes(ticket, issue)
        # skip callbacks (branch creation / initial task) — this is a mirror, not authoring
        ticket.save!(validate: true)
        was_new ? (imported += 1) : (updated += 1)
      end
    end

    Result.new(imported: imported, updated: updated, removed: removed, skipped: skipped, error: nil)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
    Result.new(imported: 0, updated: 0, removed: 0, skipped: 0, error: e.message)
  end

  private

  # "Remove the tickets we have now" — delete the project's tickets and their
  # dependent rows so GitHub can repopulate cleanly. Done inside the sync
  # transaction. Dependents without a dependent: :destroy association are cleared
  # explicitly to satisfy foreign keys.
  def purge_local_tickets!
    ticket_ids = @project.tickets.pluck(:id)
    return 0 if ticket_ids.empty?

    PullRequest.where(ticket_id: ticket_ids).update_all(ticket_id: nil) if PullRequest.column_names.include?("ticket_id")
    CiRun.where(ticket_id: ticket_ids).update_all(ticket_id: nil)       if CiRun.column_names.include?("ticket_id")
    Branch.where(ticket_id: ticket_ids).update_all(ticket_id: nil)      if Branch.column_names.include?("ticket_id")
    Activity.where(ticket_id: ticket_ids).update_all(ticket_id: nil)    if Activity.column_names.include?("ticket_id")
    CustomerTicket.where(internal_ticket_id: ticket_ids).update_all(internal_ticket_id: nil)
    TicketWatcher.where(ticket_id: ticket_ids).delete_all

    # tasks + ai_reviews cascade via dependent: :destroy
    @project.tickets.destroy_all
    ticket_ids.size
  end

  def apply_attributes(ticket, issue)
    labels = Array(issue["labels"]).map { |l| l.is_a?(Hash) ? l["name"].to_s.downcase : l.to_s.downcase }

    ticket.title        = issue["title"].presence || "Issue ##{issue['number']}"
    ticket.description  = issue["body"].to_s
    ticket.github_url   = issue["html_url"]
    ticket.github_state = issue["state"]
    ticket.status       = status_for(issue["state"])
    ticket.kind         = kind_for(labels)
    ticket.priority     = priority_for(labels)
    ticket.assignee     = user_for(issue.dig("assignee", "login"))
    ticket.label_list   = labels if ticket.respond_to?(:label_list=)
    ticket.github_synced_at = Time.current
  end

  # GitHub only has open/closed; map to the local statuses that still make sense.
  def status_for(state)
    state.to_s == "closed" ? :closed : :open
  end

  def kind_for(labels)
    labels.each { |l| return KIND_BY_LABEL[l] if KIND_BY_LABEL.key?(l) }
    :story
  end

  def priority_for(labels)
    labels.each { |l| return PRIORITY_BY_LABEL[l] if PRIORITY_BY_LABEL.key?(l) }
    :medium
  end

  # Best-effort map a GitHub login to a local user: exact github_login, then a
  # case-insensitive name/email match. Returns nil when nobody matches.
  def user_for(login)
    return nil if login.blank?

    User.find_by(github_login: login) ||
      User.where("LOWER(name) = ?", login.downcase).first ||
      User.where("LOWER(email) LIKE ?", "#{login.downcase}@%").first
  end
end
