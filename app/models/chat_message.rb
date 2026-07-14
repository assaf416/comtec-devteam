class ChatMessage < ApplicationRecord
  belongs_to :chat_room
  belongs_to :user

  has_many_attached :files

  # Set to true to skip Turbo broadcasts (e.g. bulk seeding), where rendering the
  # message partial has no live subscribers and no request context.
  cattr_accessor :skip_broadcasts, default: false

  validate :body_or_files_present

  scope :recent, -> { order(created_at: :asc) }

  # Live-update every open window on this room (Slack-style) when a new message
  # is posted. The room's show page subscribes via `turbo_stream_from`.
  after_create_commit :broadcast_new_message

  def parsed_refs
    return [] if rich_refs.blank?
    JSON.parse(rich_refs)
  rescue JSON::ParseError
    []
  end

  def edited?
    edited_at.present?
  end

  private

  def body_or_files_present
    return if body.present? || files.attached?

    errors.add(:base, "Type a message or attach a file")
  end

  def broadcast_new_message
    return if skip_broadcasts

    broadcast_append_to(
      chat_room,
      target:  "chatMessages",
      partial: "chat_messages/message",
      locals:  { message: self, is_continuation: false }
    )
  end
end
