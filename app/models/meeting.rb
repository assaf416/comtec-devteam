class Meeting < ApplicationRecord
  belongs_to :project, optional: true
  belongs_to :organizer, class_name: "User", optional: true

  has_many :meeting_attendees
  has_many :attendees, through: :meeting_attendees, source: :user
  has_many :comments, as: :commentable

  enum :meeting_type, {
    daily_standup: 0, sprint_planning: 1, sprint_review: 2,
    retrospective: 3, demo: 4, one_on_one: 5, other: 6
  }, default: :other

  enum :status, { scheduled: 0, in_progress: 1, completed: 2, cancelled: 3 }, default: :scheduled

  validates :title, :scheduled_at, presence: true

  def jitsi_url(base_url = "https://meet.jit.si")
    "#{base_url}/#{jitsi_room || "devteam-#{id}"}"
  end
end
