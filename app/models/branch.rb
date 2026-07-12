class Branch < ApplicationRecord
  belongs_to :project
  belongs_to :ticket, optional: true

  enum :status, { active: 0, merged: 1, deleted: 2 }, default: :active

  validates :name, presence: true
end
