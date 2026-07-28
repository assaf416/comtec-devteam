class ChatRoomsController < ApplicationController
  before_action :set_chat_room, only: %i[show pin unpin]

  def index
    @chat_rooms   = ChatRoom.active.order(:room_type, :name)
    @pinned_ids   = current_user.chat_room_pins.pluck(:chat_room_id)
  end

  def show
    @messages = @chat_room.chat_messages
                           .includes(:user)
                           .recent
                           .last(100)
    @message = ChatMessage.new
  end

  def pin
    current_user.chat_room_pins.find_or_create_by!(chat_room: @chat_room) { |p| p.pinned_at = Time.current }
    redirect_back fallback_location: chat_rooms_path
  end

  def unpin
    current_user.chat_room_pins.where(chat_room: @chat_room).destroy_all
    redirect_back fallback_location: chat_rooms_path
  end

  def new
    # When launched from a project context, pre-link the channel to it.
    @chat_room = ChatRoom.new(project_id: params[:project_id])
    @chat_room.room_type = :project_room if @chat_room.project_id.present?
    @projects  = Project.active.order(:name)
  end

  def create
    @chat_room = ChatRoom.new(chat_room_params)
    if @chat_room.save
      redirect_to chat_room_path(@chat_room), notice: "Channel ##{@chat_room.name} created"
    else
      @projects = Project.active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_chat_room
    @chat_room = ChatRoom.active.find(params[:id])
  end

  def chat_room_params
    params.require(:chat_room).permit(:name, :description, :room_type, :project_id)
  end
end
