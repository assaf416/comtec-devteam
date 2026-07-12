# Daily standup page: team video bar + per-developer "yesterday / today" from
# their tickets and tasks in the current sprint.
class DailyMeetingsController < ApplicationController
  include SprintSelectable

  def show
    @sprint         = resolve_sprint
    @sprint_options = selectable_sprints
    return unless @sprint

    @project = @sprint.project
    @members = @sprint.participants

    tickets    = @sprint.tickets.includes(:assignee, :tasks).to_a
    yesterday  = Date.yesterday
    @standups  = @members.map do |member|
      mine      = tickets.select { |t| t.assignee_id == member.id }
      ticket_ids = mine.map(&:id)

      done_yesterday = Task.where(ticket_id: ticket_ids)
                           .where(completed_at: yesterday.beginning_of_day..yesterday.end_of_day)
                           .includes(:ticket).order(:completed_at)

      in_progress = Task.where(ticket_id: ticket_ids)
                        .where.not(started_at: nil).where(completed_at: nil)
                        .includes(:ticket).order(:started_at)

      today_tickets = mine.reject { |t| %w[done closed].include?(t.status) }

      {
        member:         member,
        done_yesterday: done_yesterday.to_a,
        in_progress:    in_progress.to_a,
        today_tickets:  today_tickets
      }
    end
  end
end
