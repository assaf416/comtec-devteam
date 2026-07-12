class Milestone < ApplicationRecord
  belongs_to :project
  has_many :tickets

  enum :status, { open: 0, in_progress: 1, completed: 2 }, default: :open

  validates :name, presence: true
end
