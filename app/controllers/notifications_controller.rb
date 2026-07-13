class NotificationsController < ApplicationController
  before_action :set_notification, only: [ :show, :edit, :update, :destroy, :mark_read, :open_ticket ]

  def index
    @notifications = current_user.notifications
                                 .order(created_at: :desc)
                                 .limit(200)
  end

  def show; end

  def new
    @notification = current_user.notifications.build(type: "Notification")
  end

  def create
    @notification = current_user.notifications.build(notification_params)
    @notification.type = "Notification" if @notification.type.blank?

    if @notification.save
      redirect_to @notification, notice: "Notification created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @notification.update(notification_params)
      redirect_to @notification, notice: "Notification updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def mark_read
    @notification.update(read_at: Time.current)
    redirect_back fallback_location: notifications_path
  end

  def destroy
    @notification.destroy
    redirect_to notifications_path, notice: "Notification deleted successfully."
  end

  def mark_all_read
    current_user.notifications.where(read_at: nil).update_all(read_at: Time.current)
    redirect_to notifications_path, notice: "All notifications marked as read."
  end

  # Create a ticket pre-filled from this notification's data, then open it.
  def open_ticket
    project = ticket_project_for(@notification)
    unless project
      redirect_back fallback_location: notifications_path,
                    alert: "No project available to create a ticket from this notification."
      return
    end

    exception = @notification.error_text.present?
    ticket = project.tickets.create!(
      title:            notification_ticket_title(@notification),
      description:      notification_ticket_description(@notification),
      how_to_reproduce: exception ? [ @notification.error_text, @notification.backtrace_text ].compact.join("\n\n").presence : nil,
      kind:             exception ? :bug_fix : :story,
      priority:         exception ? :high : :medium,
      status:           :open,
      owner:            current_user
    )
    @notification.mark_read!
    redirect_to ticket_path(ticket), notice: "Ticket created from the notification."
  end

  private

  # Resolve a project from the notification's params (project_id / project_name),
  # falling back to an active project.
  def ticket_project_for(notification)
    data = notification.params_hash
    if (pid = data["project_id"]).present?
      proj = Project.find_by(id: pid)
      return proj if proj
    end
    if (pname = data["project_name"]).present?
      proj = Project.find_by(name: pname)
      return proj if proj
    end
    Project.active.order(:name).first || Project.order(:name).first
  end

  def notification_ticket_title(notification)
    data = notification.params_hash
    (data["ticket_title"].presence || notification.message_text.to_s.sub(/\A[^\w]*\s*/, "")).truncate(120).presence ||
      "Ticket from notification ##{notification.id}"
  end

  def notification_ticket_description(notification)
    parts = [ notification.message_text ]
    parts << "**Error:** #{notification.error_text}" if notification.error_text.present?
    if (url = notification.target_url).present?
      parts << "Source: #{url}"
    end
    parts << "_Created from notification ##{notification.id} on #{notification.created_at.strftime('%d %b %Y %H:%M')}._"
    parts.compact.join("\n\n")
  end

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end

  def notification_params
    params.require(:notification).permit(:message, :error_message, :backtrace, :read_at)
  end
end
