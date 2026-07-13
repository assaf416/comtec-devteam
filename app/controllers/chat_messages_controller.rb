class ChatMessagesController < ApplicationController
  before_action :set_chat_room

  def create
    @message = @chat_room.chat_messages.build(message_params)
    @message.user = current_user

    if @message.save
      respond_to do |format|
        # The new message reaches every open window (incl. the sender) via the
        # model's Turbo Stream broadcast; here we just reset the composer.
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "chatComposeForm", partial: "chat_rooms/compose", locals: { chat_room: @chat_room }
          )
        end
        format.html { redirect_to chat_room_path(@chat_room), status: :see_other }
      end
    else
      redirect_to chat_room_path(@chat_room), alert: @message.errors.full_messages.to_sentence
    end
  end

  private

  def set_chat_room
    @chat_room = ChatRoom.active.find(params[:chat_room_id])
  end

  def message_params
    params.require(:chat_message).permit(:body, files: [])
  end
end
