class MeetingsController < ApplicationController
  before_action :set_project, only: [ :index, :new, :create ]
  before_action :set_meeting, only: [ :show, :edit, :update, :destroy, :join, :end_meeting, :ical, :invite, :save_recording ]

  def index
    @meetings = (@project&.meetings || Meeting)
                .includes(:organizer, :project)
                .order(scheduled_at: :desc)
  end

  def show; end

  def new
    @meeting = (@project&.meetings || Meeting).build(organizer: current_user)
    # Pre-fill attendee when starting huddle from sidebar team member link
    if params[:invite].present?
      invitee = User.find_by(id: params[:invite])
      @meeting.attendees << invitee if invitee
    end
  end

  def create
    @meeting = (@project&.meetings || Meeting).build(meeting_params.merge(organizer: current_user))
    @meeting.jitsi_room ||= "devteam-#{SecureRandom.hex(6)}"
    if @meeting.save
      redirect_to @meeting, notice: "Meeting scheduled."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @meeting.update(meeting_params)
      redirect_to @meeting, notice: "Meeting updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @meeting.destroy
    redirect_to meetings_path, notice: "Meeting cancelled."
  end

  def join
    redirect_to @meeting.jitsi_url, allow_other_host: true
  end

  def end_meeting
    @meeting.update(status: :completed)
    redirect_to @meeting, notice: "Meeting marked as completed."
  end

  def invite
    user = User.find_by(id: params[:user_id])
    if user && !@meeting.attendees.include?(user)
      @meeting.attendees << user
      flash[:notice] = "#{user.display_name} invited to the meeting."
    else
      flash[:alert] = user ? "Already in meeting." : "User not found."
    end
    redirect_to @meeting
  end

  def save_recording
    if @meeting.update(recording_url: params[:recording_url])
      flash[:notice] = "Recording link saved."
    else
      flash[:alert] = "Could not save recording link."
    end
    redirect_to @meeting
  end

  def ical
    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart     = @meeting.scheduled_at
      e.dtend       = @meeting.scheduled_at + (@meeting.duration_minutes || 60).minutes
      e.summary     = @meeting.title
      e.description = "Join: #{@meeting.jitsi_url}\n\n#{@meeting.agenda}"
      e.url         = meeting_url(@meeting)
    end
    send_data cal.to_ical, filename: "meeting-#{@meeting.id}.ics", type: "text/calendar"
  end

  private

  def set_project
    @project = Project.find(params[:project_id]) if params[:project_id].present?
  end

  def set_meeting
    @meeting = Meeting.find(params[:id])
  end

  def meeting_params
    params.require(:meeting).permit(
      :title, :description, :meeting_type, :project_id, :sprint_id,
      :scheduled_at, :duration_minutes, :jitsi_room,
      :recording_url, :status, :agenda, :notes
    )
  end
end
