# Additional agile ceremonies that share the same shape (team video bar +
# sprint-scoped content): Sprint Planning, Backlog Refinement, Sprint Review.
# Daily standup and retrospective have their own dedicated controllers.
class CeremoniesController < ApplicationController
  include SprintSelectable

  KINDS = {
    "planning"   => { title: "Sprint Planning",     icon: "📋" },
    "refinement" => { title: "Backlog Refinement",  icon: "🔍" },
    "review"     => { title: "Sprint Review / Demo", icon: "🎬" }
  }.freeze

  def show
    @kind   = params[:kind]
    @meta   = KINDS.fetch(@kind)
    @sprint = resolve_sprint
    @sprint_options = selectable_sprints
    return unless @sprint

    @project = @sprint.project
    case @kind
    when "planning"   then load_planning
    when "refinement" then load_refinement
    when "review"     then load_review
    end
  end

  private

  def load_planning
    @goals          = @sprint.goals
    @members        = @sprint.participants
    @sprint_tickets = @sprint.tickets.includes(:assignee, :tasks).to_a
    @needs_estimation = @sprint_tickets.select { |t| t.story_points.blank? || t.dev_estimate_hours.blank? }
    # Candidate work to pull into the sprint.
    @backlog = @project.tickets.where(status: :backlog).includes(:assignee, :tasks).order(priority: :desc).limit(30)
    @capacity = @members.index_with do |m|
      @sprint_tickets.count { |t| t.assignee_id == m.id && !%w[done closed].include?(t.status) }
    end
  end

  def load_refinement
    not_done = @project.tickets.where.not(status: %i[done closed]).includes(:assignee, :tasks)
    @to_refine = not_done.select do |t|
      t.story_points.blank? || t.dev_estimate_hours.blank? || t.description.blank?
    end.first(40)
  end

  def load_review
    tickets    = @sprint.tickets.includes(:assignee, :pull_requests, :tasks).to_a
    @completed = tickets.select { |t| %w[done closed].include?(t.status) }
    @carryover = tickets.reject { |t| %w[done closed].include?(t.status) }
    @pull_requests = @sprint.pull_requests.includes(:ticket).order(updated_at: :desc)
  end
end
