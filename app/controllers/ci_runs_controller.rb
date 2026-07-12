class CiRunsController < ApplicationController
  before_action :set_project, only: :index
  before_action :set_ci_run, only: :show

  def index
    @ci_runs = @project.ci_runs
                       .includes(:triggered_by, :test_results)
                       .order(created_at: :desc)
                       .limit(50)
  end

  def show
    @test_results = @ci_run.test_results
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_ci_run
    @ci_run = CiRun.find(params[:id])
    @project = @ci_run.project
  end
end
