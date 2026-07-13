class TimeLogsController < ApplicationController
  before_action :set_time_log, only: %i[destroy]

  def index
    @time_logs = current_user.time_logs.includes(:project, :ticket).recent.limit(100)
    @time_log  = current_user.time_logs.build(spent_on: Date.current)
    @projects  = Project.order(:name)

    # This week's totals, per project, for a quick summary.
    week = current_user.time_logs.for_week(Date.current)
    @week_total     = week.sum(:hours)
    @week_by_project = week.joins(:project).group("projects.name").sum(:hours)
                           .sort_by { |_, h| -h }
  end

  def create
    @time_log = current_user.time_logs.build(time_log_params)
    if @time_log.save
      redirect_to time_logs_path, notice: "Logged #{@time_log.hours}h."
    else
      @time_logs = current_user.time_logs.includes(:project, :ticket).recent.limit(100)
      @projects  = Project.order(:name)
      week = current_user.time_logs.for_week(Date.current)
      @week_total      = week.sum(:hours)
      @week_by_project = week.joins(:project).group("projects.name").sum(:hours).sort_by { |_, h| -h }
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @time_log.destroy
    redirect_to time_logs_path, notice: "Time entry removed."
  end

  private

  def set_time_log
    @time_log = current_user.time_logs.find(params[:id])
  end

  def time_log_params
    params.require(:time_log).permit(:project_id, :ticket_id, :hours, :spent_on, :note)
  end
end
