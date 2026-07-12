class CiRun < ApplicationRecord
  belongs_to :project
  belongs_to :ticket, optional: true
  belongs_to :triggered_by, class_name: "User", optional: true

  has_many :test_results

  enum :status, { pending: 0, running: 1, passed: 2, failed: 3, cancelled: 4, error: 5 }, default: :pending

  validates :build_number, presence: true

  def duration
    return nil unless started_at && finished_at
    ((finished_at - started_at) / 60).round(1)
  end
end
