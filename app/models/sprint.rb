class Sprint < ApplicationRecord
  belongs_to :project

  has_many :tickets
  has_many :meetings
  has_many :pull_requests, through: :tickets
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :ai_reviews, as: :reviewable, dependent: :destroy
  has_many :documents, dependent: :nullify

  enum :status, { planning: 0, active: 1, completed: 2, cancelled: 3 }, default: :planning

  validates :name, presence: true
  validates :start_date, :end_date, presence: true
  validate :end_date_after_start_date

  # Only one sprint per project may be active ("current") at a time — whenever a
  # sprint becomes active, any other active sprint in the project is closed out.
  after_save :enforce_single_current, if: -> { saved_change_to_status? && active? }

  scope :active,    -> { where(status: :active) }
  scope :planning,  -> { where(status: :planning) }
  scope :completed, -> { where(status: :completed) }
  scope :current,   -> { active.where("start_date <= ? AND end_date >= ?", Date.today, Date.today) }
  scope :upcoming,  -> { where("start_date > ?", Date.today).order(:start_date) }

  # The "current" sprint of a project is its active one.
  def current?
    active?
  end

  # Make this the project's current sprint (activates it; closes the previous one).
  def make_current!
    update!(status: :active)
  end

  # Everyone involved in the sprint = the distinct assignees and owners of its tickets.
  def participants
    ids = tickets.pluck(:assignee_id, :owner_id).flatten.compact.uniq
    User.where(id: ids).order(:name)
  end

  # Estimated hours across the sprint's tickets (dev + QA estimates).
  def total_estimated_hours
    tickets.to_a.sum { |t| (t.dev_estimate_hours || 0) + (t.tester_estimate_hours || 0) }.round(1)
  end

  # Actual hours logged across the sprint's tickets.
  def total_actual_hours
    tickets.to_a.sum { |t| t.actual_hours_in_hours || 0 }.round(1)
  end

  def duration_days
    (end_date - start_date).to_i
  end

  def days_remaining
    [ (end_date - Date.today).to_i, 0 ].max
  end

  def progress_percent
    total = tickets.count
    return 0 if total.zero?
    done = tickets.where(status: %i[done closed]).count
    (done * 100.0 / total).round
  end

  private

  # Close any other active sprint in the same project (update_all skips callbacks
  # so this never recurses).
  def enforce_single_current
    project.sprints.active.where.not(id: id)
           .update_all(status: :completed, updated_at: Time.current)
  end

  def end_date_after_start_date
    return unless start_date && end_date
    errors.add(:end_date, "must be after start date") if end_date < start_date
  end
end
