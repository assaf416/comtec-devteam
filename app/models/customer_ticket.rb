class CustomerTicket < ApplicationRecord
  belongs_to :customer
  belongs_to :assigned_to, class_name: "User",   optional: true
  belongs_to :internal_ticket, class_name: "Ticket", optional: true

  enum :ticket_type, { support: 0, feature_request: 1 }, prefix: true
  enum :status,   { open: 0, in_progress: 1, waiting_for_customer: 2, resolved: 3, closed: 4 }, prefix: true
  enum :priority, { low: 0, medium: 1, high: 2, critical: 3 }, prefix: true

  validates :title,  presence: true
  validates :status, presence: true

  scope :open_tickets,   -> { where(status: [ :open, :in_progress, :waiting_for_customer ]) }
  scope :resolved,       -> { where(status: [ :resolved, :closed ]) }
  scope :high_priority,  -> { where(priority: [ :high, :critical ]) }

  def resolve!
    update!(status: :resolved, resolved_at: Time.current)
  end

  def link_to_internal!(ticket)
    update!(internal_ticket: ticket)
  end
end
