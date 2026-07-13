# A logged block of work time — who spent how many hours on which project (and
# optionally which ticket) on a given day. Powers the "Time logging" screen.
class TimeLog < ApplicationRecord
  belongs_to :user
  belongs_to :project
  belongs_to :ticket, optional: true

  validates :hours, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 24 }
  validates :spent_on, presence: true

  scope :recent, -> { order(spent_on: :desc, created_at: :desc) }
  scope :for_week, ->(date) { where(spent_on: date.beginning_of_week..date.end_of_week) }
end
