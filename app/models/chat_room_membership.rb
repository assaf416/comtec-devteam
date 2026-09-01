# A user's membership in a chat room. A user can belong to many rooms at
# once (has_many, not has_one) — surfaced on the Today page ("My Chat Rooms").
class ChatRoomMembership < ApplicationRecord
  belongs_to :user
  belongs_to :chat_room

  validates :chat_room_id, uniqueness: { scope: :user_id }
end
