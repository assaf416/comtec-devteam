class PullRequestsController < ApplicationController
  before_action :set_project, only: [ :index ]
  before_action :set_pull_request, only: [ :show, :sync, :cockpit, :merge ]

  def index
    @pull_requests = @project.pull_requests
                              .includes(:ticket)
                              .order(updated_at: :desc)
    @pull_requests = @pull_requests.where(status: params[:status]) if params[:status].present?
  end

  def show; end

  def sync
    SyncPullRequestJob.perform_later(@pull_request.id)
    redirect_to @pull_request, notice: "Sync started — data will refresh in a moment."
  end

  # The merge cockpit: mergeability signals + conflict resolver.
  def cockpit
    @analysis = Git::MergeService.new.analyze(@pull_request)
  end

  # Mark the PR merged (the resolver confirms conflicts were settled client-side).
  def merge
    if @pull_request.status == "merged"
      redirect_to cockpit_pull_request_path(@pull_request), alert: "Already merged." and return
    end

    @pull_request.update(status: :merged, merged_at: Time.current)
    redirect_to cockpit_pull_request_path(@pull_request),
                notice: "✅ Merged ##{@pull_request.pr_number} — #{@pull_request.title.truncate(50)}."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_pull_request
    @pull_request = PullRequest.find(params[:id])
    @project = @pull_request.project
  end
end
