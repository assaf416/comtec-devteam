# A "Chat with AI" conversation — context-aware over a project/sprint.
class AiChatSession < ApplicationRecord
  belongs_to :user
  belongs_to :project, optional: true
  belongs_to :sprint,  optional: true

  has_many :ai_chat_messages, -> { order(:created_at) }, dependent: :destroy

  scope :recent, -> { order(updated_at: :desc) }

  def display_title
    title.presence || "New chat"
  end
end
