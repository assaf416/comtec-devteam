class CustomerMessage < ApplicationRecord
  belongs_to :customer
  belongs_to :sender, polymorphic: true  # CustomerUser or User

  validates :body, presence: true

  # Only show messages not marked as internal to portal users
  scope :visible_to_portal, -> { where(internal_only: false) }
  scope :recent,             -> { order(created_at: :asc) }
end
