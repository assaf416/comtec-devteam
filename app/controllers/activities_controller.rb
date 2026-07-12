class ActivitiesController < ApplicationController
  before_action :set_project

  def index
    @activities = @project.activities
                           .includes(:user, :subject_user, :ticket)
                           .recent
                           .limit(100)

    @filter = params[:event_type].presence

    @activities = @activities.where(event_type: @filter) if @filter.present?
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end
end
