# A personal note. Created in one keystroke (quick capture) and then managed —
# edited, pinned to the top, or archived.
class Note < ApplicationRecord
  belongs_to :user

  validates :body, presence: true, unless: -> { title.present? }

  scope :active,   -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }
  # Pinned first, then most-recently-updated.
  scope :sorted,   -> { order(pinned: :desc, updated_at: :desc) }

  def display_title
    title.presence || body.to_s.split("\n").first.to_s.truncate(60).presence || "Untitled note"
  end
end
