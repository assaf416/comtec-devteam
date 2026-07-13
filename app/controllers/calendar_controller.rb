class CalendarController < ApplicationController
  # GET /calendar
  def index
  end

  # GET /calendar/events.json
  # Params: start (ISO8601), end (ISO8601)
  def events
    range_start = params[:start]&.to_datetime
    range_end   = params[:end]&.to_datetime

    project_ids = current_user.member_projects.pluck(:id)
    events = []

    # ── Meetings (organized or attending) ─────────────────────────────────
    meetings = Meeting
      .includes(:project)
      .where(
        Meeting.arel_table[:organizer_id].eq(current_user.id)
          .or(Meeting.arel_table[:id].in(
            MeetingAttendee.where(user_id: current_user.id).select(:meeting_id)
          ))
      )
    meetings = meetings.where(scheduled_at: range_start..range_end) if range_start && range_end

    meetings.each do |m|
      duration = (m.duration_minutes || 60).minutes
      events << {
        id:    "meeting-#{m.id}",
        title: m.title,
        start: m.scheduled_at&.iso8601,
        end:   m.scheduled_at ? (m.scheduled_at + duration).iso8601 : nil,
        url:   meeting_path(m),
        color: "#4a90d9",
        extendedProps: { type: "meeting", project: m.project&.name }
      }
    end

    # ── Milestones ─────────────────────────────────────────────────────────
    milestones = Milestone.includes(:project).where(project_id: project_ids)
    milestones = milestones.where(due_date: range_start..range_end) if range_start && range_end

    milestones.each do |ms|
      events << {
        id:    "milestone-#{ms.id}",
        title: "🏁 #{ms.name}",
        start: ms.due_date&.iso8601,
        allDay: true,
        url:   project_path(ms.project),
        color: "#e84545",
        extendedProps: { type: "milestone", project: ms.project.name }
      }
    end

    render json: events
  end
end
