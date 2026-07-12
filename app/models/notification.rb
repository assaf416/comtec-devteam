class Notification < ApplicationRecord
  belongs_to :recipient, polymorphic: true

  serialize :params, coder: JSON

  scope :unread, -> { where(read_at: nil) }
  scope :read,   -> { where.not(read_at: nil) }

  def read?
    read_at.present?
  end

  def mark_read!
    update(read_at: Time.current) unless read?
  end

  def message_text
    message.presence || params_hash["message"].presence || type.to_s.humanize
  end

  def error_text
    error_message.presence || params_hash["error_message"].presence
  end

  def backtrace_text
    backtrace.presence || params_hash["backtrace"].presence
  end

  def target_url
    params_hash["url"].presence
  end

  def params_hash
    params.is_a?(Hash) ? params : {}
  end
end
