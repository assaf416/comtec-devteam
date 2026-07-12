class ChatMessage < ApplicationRecord
  belongs_to :chat_room
  belongs_to :user

  validates :body, presence: true

  scope :recent, -> { order(created_at: :asc) }

  def parsed_refs
    return [] if rich_refs.blank?
    JSON.parse(rich_refs)
  rescue JSON::ParseError
    []
  end

  def edited?
    edited_at.present?
  end
end
