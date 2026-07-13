class AttachmentView < ApplicationRecord
  belongs_to :user
  belongs_to :attachment

  validates :attachment_id, uniqueness: { scope: :user_id }

  # Record (or refresh) that a user just opened an attachment.
  def self.record(user:, attachment:)
    view = find_or_initialize_by(user: user, attachment: attachment)
    view.update(viewed_at: Time.current)
    view
  end
end
