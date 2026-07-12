class ChatRoom < ApplicationRecord
  belongs_to :project, optional: true
  has_many :chat_messages, dependent: :destroy

  enum :room_type, { general: 0, project_room: 1, incident: 2, announcement: 3 }, default: :general

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :active,         -> { where(archived: false) }
  scope :general_rooms,  -> { active.where(project_id: nil) }
  scope :project_rooms,  -> { active.where.not(project_id: nil) }

  def last_message
    chat_messages.order(created_at: :desc).first
  end
end
