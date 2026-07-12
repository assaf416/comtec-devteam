class SyncPullRequestJob < ApplicationJob
  queue_as :default

  def perform(pull_request_id)
    pr = PullRequest.find_by(id: pull_request_id)
    return unless pr

    project   = pr.project
    repo_url  = project.repo_url.presence
    return unless repo_url

    owner, repo = GiteaService.repo_parts(repo_url)
    return unless owner && repo

    gitea = GiteaService.new

    # ── 1. Changed files ──────────────────────────────────────────
    files = gitea.pull_request_files(repo_owner: owner, repo_name: repo, pr_number: pr.pr_number)

    # ── 2. Diff (split into source vs test) ───────────────────────
    diff = gitea.pull_request_diff(repo_owner: owner, repo_name: repo, pr_number: pr.pr_number) || ""
    source_diff, test_diff = split_diff_by_type(diff)

    # ── 3. Comments ───────────────────────────────────────────────
    comments = gitea.pull_request_comments(repo_owner: owner, repo_name: repo, pr_number: pr.pr_number)

    # ── 4. CI / test results via commit statuses ──────────────────
    pr_meta  = gitea.pull_request(repo_owner: owner, repo_name: repo, pr_number: pr.pr_number)
    head_sha = pr_meta&.dig("head", "sha")
    statuses = head_sha ? gitea.commit_statuses(repo_owner: owner, repo_name: repo, sha: head_sha) : []

    test_results = statuses.map do |s|
      { "context" => s["context"], "state" => s["state"],
        "description" => s["description"], "target_url" => s["target_url"] }
    end

    build_errors = statuses.select { |s| s["state"] == "failure" }
                            .map { |s| "#{s['context']}: #{s['description']}" }
                            .join("\n")

    # ── 5. Persist ────────────────────────────────────────────────
    pr.update!(
      files_changed:       files,
      code_changed:        source_diff,
      test_code:           test_diff,
      pr_comments_data:    comments,
      latest_test_results: test_results,
      build_errors:        build_errors.presence,
      synced_at:           Time.current
    )

    Rails.logger.info "SyncPullRequestJob: PR ##{pr.pr_number} synced (#{files.size} files, #{comments.size} comments)"
  rescue => e
    Rails.logger.error "SyncPullRequestJob failed for PR #{pull_request_id}: #{e.message}"
    raise
  end

  private

  # Split a unified diff into source-code hunks vs test-file hunks
  def split_diff_by_type(diff)
    return [ "", "" ] if diff.blank?

    source_sections = []
    test_sections   = []
    current_file    = nil
    current_lines   = []

    diff.each_line do |line|
      if line.start_with?("diff --git")
        # flush previous section
        flush_section(current_file, current_lines, source_sections, test_sections)
        current_file  = line
        current_lines = [ line ]
      else
        current_lines << line
      end
    end
    flush_section(current_file, current_lines, source_sections, test_sections)

    [ source_sections.join, test_sections.join ]
  end

  def flush_section(filename, lines, source_acc, test_acc)
    return unless filename
    if filename.match?(/spec|test|_test\.|_spec\./)
      test_acc << lines.join
    else
      source_acc << lines.join
    end
  end
end
