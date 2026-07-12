class AiChatMessage < ApplicationRecord
  belongs_to :ai_chat_session, touch: true

  validates :role, :content, presence: true

  def user?
    role == "user"
  end

  def assistant?
    role == "assistant"
  end
end
