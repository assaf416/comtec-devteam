class DashboardController < ApplicationController
  def index
    @projects          = Project.active.order(:name)
    @my_tickets        = current_user.assigned_tickets.where.not(status: [ :done, :closed ]).includes(:project, :sprint).order(priority: :desc).limit(10)
    @recent_ci_runs    = CiRun.includes(:project, :ticket).order(created_at: :desc).limit(10)
    @recent_deployments = Deployment.includes(:project, :client_account).order(created_at: :desc).limit(10)
    @upcoming_meetings = Meeting.where("scheduled_at >= ?", Time.current).order(:scheduled_at).limit(5)
    @failing_ci_runs   = CiRun.where(status: :failed).includes(:project).order(created_at: :desc).limit(5)
    @ci_stats = {
      total:   CiRun.where(created_at: 1.week.ago..Time.current).count,
      passed:  CiRun.passed.where(created_at: 1.week.ago..Time.current).count,
      failed:  CiRun.failed.where(created_at: 1.week.ago..Time.current).count
    }
  end
end
