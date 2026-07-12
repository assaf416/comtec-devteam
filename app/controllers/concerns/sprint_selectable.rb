# Shared sprint resolution for the ceremony pages (daily standup / retro):
# pick the sprint from ?sprint_id=, else default to the current active sprint.
module SprintSelectable
  extend ActiveSupport::Concern

  private

  def resolve_sprint
    if params[:sprint_id].present?
      Sprint.find_by(id: params[:sprint_id])
    else
      Sprint.active.order(start_date: :desc).first || Sprint.order(end_date: :desc).first
    end
  end

  def selectable_sprints
    Sprint.includes(:project).order(end_date: :desc).limit(60)
  end
end
