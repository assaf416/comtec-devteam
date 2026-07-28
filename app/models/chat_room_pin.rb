# A user's personal "quick access" chat rooms, shown in the sidebar chat
# menu (latest 5, capped in the query — see User#pinned_chat_rooms usage).
class ChatRoomPin < ApplicationRecord
  belongs_to :user
  belongs_to :chat_room

  validates :chat_room_id, uniqueness: { scope: :user_id }
end
