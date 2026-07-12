class ProjectMembership < ApplicationRecord
  belongs_to :project
  belongs_to :user

  enum :role, { developer: 0, viewer: 1, lead: 2, qa: 3 }, default: :developer

  validates :user_id, uniqueness: {
    scope: :project_id,
    message: "is already a member of this project"
  }

  scope :by_role, ->(r) { where(role: r) }
  scope :leads,   -> { where(role: :lead) }
end
