class ChatMessagesController < ApplicationController
  before_action :set_chat_room

  def create
    @message = @chat_room.chat_messages.build(
      body: params.dig(:chat_message, :body).to_s.strip,
      user: current_user
    )

    if @message.body.present? && @message.save
      redirect_to chat_room_path(@chat_room), status: :see_other
    else
      redirect_to chat_room_path(@chat_room), alert: "Message can't be blank"
    end
  end

  private

  def set_chat_room
    @chat_room = ChatRoom.active.find(params[:chat_room_id])
  end
end
