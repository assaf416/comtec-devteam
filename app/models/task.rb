# A unit of work under a ticket. Breaking a story into tasks makes estimation
# easier and lets us derive a story's progress from how many tasks are complete.
# Status is derived from the started_at / completed_at timestamps.
class Task < ApplicationRecord
  belongs_to :ticket
  belongs_to :user, optional: true

  validates :description, presence: true

  # Keep the ticket's cached task rollups (progress / estimation) in sync.
  after_commit :refresh_ticket_stats

  scope :completed,   -> { where.not(completed_at: nil) }
  scope :in_progress, -> { where.not(started_at: nil).where(completed_at: nil) }
  scope :not_started, -> { where(started_at: nil, completed_at: nil) }
  scope :ordered,     -> { order(:created_at) }

  def status
    return "completed"   if completed_at.present?
    return "in_progress" if started_at.present?
    "not_started"
  end

  def completed?
    completed_at.present?
  end

  def start!
    return if completed?
    update!(started_at: started_at || Time.current)
  end

  def complete!
    update!(started_at: started_at || Time.current, completed_at: Time.current)
  end

  def reopen!
    update!(completed_at: nil)
  end

  STATUS_BADGES = {
    "not_started" => "bg-secondary",
    "in_progress" => "bg-info text-dark",
    "completed"   => "bg-success"
  }.freeze

  def status_badge_class
    STATUS_BADGES.fetch(status, "bg-secondary")
  end

  # Parse a free-form duration like "4h", "1d", "2d 4h" into hours (1 day = 8h).
  def self.parse_hours(value)
    return nil if value.blank?

    s = value.to_s.downcase.strip
    total = 0.0
    matched = false
    s.scan(/(\d+(?:\.\d+)?)\s*d/)  { |v| total += v.first.to_f * 8.0; matched = true }
    s.scan(/(\d+(?:\.\d+)?)\s*h/)  { |v| total += v.first.to_f;       matched = true }
    return total.round(2) if matched

    Float(s)
  rescue ArgumentError, TypeError
    nil
  end

  def estimation_in_hours
    self.class.parse_hours(estimation)
  end

  def actual_in_hours
    self.class.parse_hours(actual)
  end

  private

  def refresh_ticket_stats
    Ticket.find_by(id: ticket_id)&.recalculate_task_stats!
  end
end
