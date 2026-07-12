class TicketMailer < ApplicationMailer
  def assigned(ticket)
    @ticket = ticket
    @user   = ticket.assignee
    mail(
      to:      @user.email,
      subject: t("mailers.ticket_assigned", ticket_id: ticket.id, title: ticket.title)
    )
  end

  def status_changed(ticket, watcher)
    @ticket  = ticket
    @user    = watcher
    mail(
      to:      @user.email,
      subject: t("mailers.ticket_status_changed", ticket_id: ticket.id, status: ticket.status)
    )
  end

  def ci_failed(ticket)
    @ticket  = ticket
    @user    = ticket.assignee
    @ci_run  = ticket.latest_ci_run
    mail(
      to:      @user.email,
      subject: t("mailers.ci_failed", ticket_id: ticket.id)
    )
  end

  def deploy_failed(ticket)
    @ticket = ticket
    @user   = ticket.assignee
    mail(
      to:      @user.email,
      subject: t("mailers.deploy_failed", ticket_id: ticket.id)
    )
  end
end
