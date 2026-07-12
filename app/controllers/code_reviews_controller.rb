# Code Review tool — paste a Gitea PR URL to review its changes, files and test
# results, and leave comments. PR data is fetched live from Gitea; the review,
# decision and comments are persisted in-app.
class CodeReviewsController < ApplicationController
  before_action :set_code_review, only: %i[show update refresh ai_review]

  def index
    @code_reviews = CodeReview.includes(:reviewer).recent.page(params[:page])
  end

  def new
    @code_review = CodeReview.new
  end

  def create
    parsed = CodeReview.parse_url(params[:pr_url])
    if parsed.nil?
      redirect_to new_code_review_path,
                  alert: "Could not parse that URL. Paste a Gitea pull request URL like " \
                         "http://gitea/owner/repo/pulls/42."
      return
    end

    @code_review = CodeReview.new(pr_url: params[:pr_url].to_s.strip, reviewer: current_user, **parsed)
    @code_review.project = matching_project(parsed)
    apply_gitea_metadata(@code_review, parsed)

    if @code_review.save
      redirect_to @code_review, notice: @metadata_notice
    else
      flash.now[:alert] = @code_review.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @comments = @code_review.comments.includes(:author).order(:created_at)
    @comment  = Comment.new
    @ai_reviews = @code_review.ai_reviews.order(created_at: :desc)
    load_pr_data
    load_test_results
  end

  # Update the review decision (approve / request changes / comment) + summary.
  def update
    if @code_review.update(code_review_params)
      redirect_to @code_review, notice: "Review updated."
    else
      redirect_to @code_review, alert: @code_review.errors.full_messages.to_sentence
    end
  end

  # Re-fetch PR metadata from Gitea.
  def refresh
    apply_gitea_metadata(@code_review, parsed_parts)
    @code_review.save
    redirect_to @code_review, notice: @metadata_notice
  end

  # Run the local-LLM code review on the PR diff.
  def ai_review
    diff = fetch_diff
    review = Ai::CodeReviewService.new(
      reviewable: @code_review, user: current_user,
      diff: diff, language: params[:language]
    ).call
    notice = review.status_failed? ? "AI review could not complete: #{review.error_message}" : "AI review completed."
    redirect_to code_review_path(@code_review, anchor: "ai"), notice: notice
  end

  private

  def set_code_review
    @code_review = CodeReview.find(params[:id])
  end

  def code_review_params
    params.require(:code_review).permit(:status, :summary)
  end

  def parsed_parts
    { repo_owner: @code_review.repo_owner, repo_name: @code_review.repo_name, pr_number: @code_review.pr_number }
  end

  # Resolve the in-app project whose repo_url matches the PR's owner/repo.
  def matching_project(parsed)
    Project.where.not(repo_url: [ nil, "" ]).find do |p|
      GiteaService.repo_parts(p.repo_url) == [ parsed[:repo_owner], parsed[:repo_name] ]
    end
  end

  def apply_gitea_metadata(review, parsed)
    meta = gitea.pull_request(repo_owner: parsed[:repo_owner], repo_name: parsed[:repo_name], pr_number: parsed[:pr_number])
    if meta
      review.title       = meta["title"].presence || review.title
      review.author      = meta.dig("user", "login")
      review.head_branch = meta.dig("head", "ref")
      review.base_branch = meta.dig("base", "ref")
      review.gitea_state = meta["state"]
      @pr_meta = meta
      @metadata_notice = "Code review opened for PR ##{parsed[:pr_number]}."
    else
      review.title ||= "PR ##{parsed[:pr_number]}"
      @metadata_notice = "Opened, but could not reach Gitea to load PR metadata — check GITEA_URL/token."
    end
  end

  def load_pr_data
    parts = parsed_parts
    @pr_meta       ||= gitea.pull_request(**parts)
    @file_details   = gitea.pull_request_file_details(**parts)
    @diff           = gitea.pull_request_diff(**parts).to_s
    @gitea_comments = gitea.pull_request_comments(**parts)
    @gitea_online   = @pr_meta.present? || @file_details.any? || @diff.present?
  end

  def fetch_diff
    gitea.pull_request_diff(**parsed_parts).to_s
  end

  # Test results: Gitea commit statuses for the head commit + the latest in-app
  # CI run for the PR's branch (with its parsed test-suite results).
  def load_test_results
    head_sha = @pr_meta&.dig("head", "sha")
    @commit_statuses = head_sha ? gitea.commit_statuses(repo_owner: @code_review.repo_owner, repo_name: @code_review.repo_name, sha: head_sha) : []

    @ci_run = nil
    if @code_review.project && @code_review.head_branch.present?
      @ci_run = @code_review.project.ci_runs
                            .where(branch_name: @code_review.head_branch)
                            .order(created_at: :desc).first
    end
    @ci_test_results = @ci_run ? @ci_run.test_results.to_a : []
  end

  def gitea
    @gitea ||= GiteaService.new
  end
end
