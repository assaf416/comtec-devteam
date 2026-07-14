class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { developer: 0, team_lead: 1, project_manager: 2, admin: 3, qa: 4 }, default: :developer
  enum :preferred_language, { en: "en", he: "he" }, prefix: :lang, default: "he"

  has_one_attached :avatar

  has_many :time_logs, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :todo_lists, dependent: :destroy
  has_many :assigned_tickets, class_name: "Ticket", foreign_key: :assignee_id
  has_many :estimated_tickets, class_name: "Ticket", foreign_key: :estimated_by_id
  has_many :triggered_ci_runs, class_name: "CiRun", foreign_key: :triggered_by_id
  has_many :deployments, foreign_key: :deployed_by_id
  has_many :authored_documents, class_name: "Document", foreign_key: :author_id
  has_many :comments, foreign_key: :author_id
  has_many :organized_meetings, class_name: "Meeting", foreign_key: :organizer_id
  has_many :meeting_attendees
  has_many :meetings, through: :meeting_attendees
  has_many :ticket_watchers
  has_many :watched_tickets, through: :ticket_watchers, source: :ticket
  has_many :notifications, as: :recipient, dependent: :destroy
  has_many :assigned_customer_tickets, class_name: "CustomerTicket", foreign_key: :assigned_to_id
  has_many :project_memberships, dependent: :destroy
  has_many :member_projects, through: :project_memberships, source: :project
  has_many :activities,        foreign_key: :user_id,         dependent: :destroy
  has_many :subject_activities, class_name: "Activity", foreign_key: :subject_user_id, dependent: :nullify
  has_many :ai_chat_sessions, dependent: :destroy
  has_many :uploaded_attachments, class_name: "Attachment", foreign_key: :uploaded_by_id, dependent: :nullify
  has_many :attachment_views, dependent: :destroy
  has_many :recently_viewed_attachments, through: :attachment_views, source: :attachment

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validate :acceptable_avatar

  before_create :generate_api_token

  def admin?
    role == "admin"
  end

  # Devise: a blocked user cannot sign in (and is signed out on next request).
  # Blocking is reversible by an admin.
  def active_for_authentication?
    super && !blocked?
  end

  def inactive_message
    blocked? ? :blocked : super
  end

  def display_name
    name.presence || email.split("@").first
  end

  def initials
    parts = display_name.split
    if parts.size >= 2
      "#{parts.first[0]}#{parts.last[0]}".upcase
    else
      display_name.first(2).upcase
    end
  end

  def regenerate_api_token!
    update!(api_token: SecureRandom.hex(32))
  end

  private

  def generate_api_token
    self.api_token ||= SecureRandom.hex(32)
  end

  def acceptable_avatar
    return unless avatar.attached?

    unless avatar.blob.content_type.in?(%w[image/png image/jpeg image/gif image/webp image/svg+xml])
      errors.add(:avatar, "must be a PNG, JPEG, GIF, or WebP image")
    end

    if avatar.blob.byte_size > 5.megabytes
      errors.add(:avatar, "must be less than 5 MB")
    end
  end
end
