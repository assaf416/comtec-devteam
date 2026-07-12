# Edit a Cucumber feature file in a dark, console-style editor with Gherkin
# highlighting, and review/improve it with the local AI (Ai::TestReviewService).
# Reached from the "Files changed" panel on a ticket for .feature files.
class CucumberTestsController < ApplicationController
  before_action :set_context

  def edit
    @content = loaded_content
  end

  # Run the AI test review on the (edited) feature content; re-render the editor.
  def review
    @content = params[:content].to_s
    @review  = Ai::TestReviewService.new(reviewable: @ticket, user: current_user, feature: @content).call
    render :edit
  end

  private

  def set_context
    @pull_request = PullRequest.find_by(id: params[:pull_request_id])
    @ticket  = @pull_request&.ticket || Ticket.find_by(id: params[:ticket_id])
    @project = @ticket&.project || @pull_request&.project
    @path    = params[:path].to_s
  end

  # Editor seed: posted content wins; otherwise the file's content from the PR;
  # otherwise fetch from the project's Gitea repo (best-effort); otherwise a starter.
  def loaded_content
    return params[:content] if params[:content].present?

    pr_file_content.presence || fetch_from_gitea.presence || starter_template
  end

  # Content of @path from the pull request's stored files (seeded fake data).
  def pr_file_content
    return nil unless @pull_request && @path.present?

    file = @pull_request.pr_files.find { |f| f["path"].to_s == @path }
    file && file["content"]
  end

  def fetch_from_gitea
    return nil unless @project&.repo_url.present? && @path.present?

    owner, repo = GiteaService.repo_parts(@project.repo_url)
    return nil unless owner && repo

    branch = @ticket&.branch_name.presence || @project.default_branch.presence || "main"
    GiteaService.new.file_content(repo_owner: owner, repo_name: repo, path: @path, ref: branch)
  end

  def starter_template
    name = File.basename(@path.presence || "feature", ".feature").tr("_-", "  ").strip
    <<~GHERKIN
      Feature: #{name.presence || 'New feature'}
        As a user
        I want to …
        So that …

        Scenario: Happy path
          Given …
          When …
          Then …
    GHERKIN
  end
end
