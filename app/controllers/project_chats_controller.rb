class ProjectChatsController < ApplicationController
  before_action :set_project

  # Per-project chat page. Shows one of the project's channels (the one named by
  # ?channel=, otherwise the project's default room) and lets the team post
  # messages with image/file attachments. Setting @project keeps the sidebar in
  # project context so the "Project Chat" link stays highlighted.
  def show
    @chat_room = current_room
    @rooms     = @project.chat_rooms.active.order(:created_at, :id)
    @messages  = @chat_room.chat_messages.includes(:user).recent.last(100)
    @message   = ChatMessage.new
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def current_room
    rooms = @project.chat_rooms.active
    room  = rooms.find_by(id: params[:channel]) if params[:channel].present?
    room ||= rooms.order(:created_at, :id).first
    room || @project.chat_rooms.create!(
      name:        default_room_name,
      description: "#{@project.name} team channel",
      room_type:   :project_room
    )
  end

  # Room names are globally unique; derive a stable, collision-resistant slug.
  def default_room_name
    base = @project.name.parameterize.presence || "project-#{@project.id}"
    ChatRoom.exists?(name: base) ? "#{base}-#{@project.id}" : base
  end
end
