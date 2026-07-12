class Activity < ApplicationRecord
  belongs_to :project
  belongs_to :user                                           # actor (who did it)
  belongs_to :subject_user, class_name: "User", optional: true  # user acted upon
  belongs_to :ticket, optional: true                         # linked story / ticket

  serialize :metadata, coder: JSON

  enum :event_type, {
    member_added:     0,
    member_removed:   1,
    exception_raised: 2,
    ci_passed:        3,
    ci_failed:        4,
    deployment_done:  5,
    ticket_created:   6,
    ticket_resolved:  7,
    pr_merged:        8,
    custom:           9
  }, default: :custom

  validates :description, presence: true

  scope :recent,        -> { order(created_at: :desc) }
  scope :for_project,   ->(p) { where(project: p) }
  scope :exceptions,    -> { where(event_type: :exception_raised) }
  scope :membership,    -> { where(event_type: %i[member_added member_removed]) }

  # Human-readable icon for each event type
  EVENT_ICONS = {
    "member_added"     => "➕",
    "member_removed"   => "➖",
    "exception_raised" => "🔥",
    "ci_passed"        => "✅",
    "ci_failed"        => "❌",
    "deployment_done"  => "🚀",
    "ticket_created"   => "🎫",
    "ticket_resolved"  => "✔️",
    "pr_merged"        => "🔀",
    "custom"           => "📌"
  }.freeze

  def icon
    EVENT_ICONS[event_type] || "📌"
  end

  def parsed_metadata
    return {} if metadata.blank?
    metadata.is_a?(Hash) ? metadata : JSON.parse(metadata.to_s)
  rescue JSON::ParseError
    {}
  end
end
