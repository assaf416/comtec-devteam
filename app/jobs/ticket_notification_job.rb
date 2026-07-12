class TicketNotificationJob < ApplicationJob
  queue_as :default

  def perform(ticket_id, event)
    ticket = Ticket.includes(:project, :assignee, :watchers).find_by(id: ticket_id)
    return unless ticket

    case event
    when "assigned"
      TicketMailer.assigned(ticket).deliver_later if ticket.assignee
    when "status_changed"
      ticket.watchers.each { |w| TicketMailer.status_changed(ticket, w).deliver_later }
    when "ci_failed"
      TicketMailer.ci_failed(ticket).deliver_later if ticket.assignee
    when "deploy_failed"
      TicketMailer.deploy_failed(ticket).deliver_later if ticket.assignee
    end
  end
end
