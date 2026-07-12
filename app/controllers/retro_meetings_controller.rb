# Sprint retrospective page: team video bar + this sprint's performance, a trend
# comparison against recent sprints, and a per-developer performance report.
class RetroMeetingsController < ApplicationController
  include SprintSelectable

  def show
    @sprint         = resolve_sprint
    @sprint_options = selectable_sprints
    return unless @sprint

    @project = @sprint.project
    @report  = SprintRetroReport.new(@sprint)
  end
end
