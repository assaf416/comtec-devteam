module CustomerPortal
  class DashboardController < BaseController
    def index
      @open_tickets    = current_customer.customer_tickets.where(ticket_type: :support).open_tickets.count
      @open_stories    = current_customer.customer_tickets.where(ticket_type: :feature_request).open_tickets.count
      @unread_messages = current_customer.customer_messages.visible_to_portal.where("created_at > ?", 7.days.ago).count
      @project_ids     = current_customer.installations.pluck(:project_id).compact.uniq

      @recent_tickets = current_customer.customer_tickets
                          .where(ticket_type: :support)
                          .order(updated_at: :desc)
                          .limit(5)

      @recent_stories = current_customer.customer_tickets
                          .where(ticket_type: :feature_request)
                          .order(updated_at: :desc)
                          .limit(5)

      @latest_messages = current_customer.customer_messages
                           .visible_to_portal
                           .recent
                           .last(5)

      @upcoming_milestones = Milestone.where(project_id: @project_ids)
                               .where.not(status: :completed)
                               .where("due_date >= ?", Date.today)
                               .order(:due_date)
                               .limit(5)
    end
  end
end
