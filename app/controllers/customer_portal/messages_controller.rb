module CustomerPortal
  class MessagesController < BaseController
    def index
      @messages = current_customer.customer_messages.visible_to_portal.recent
      @new_message = CustomerMessage.new
    end

    def create
      @new_message = current_customer.customer_messages.new(
        sender:       current_customer_user,
        body:         params.dig(:customer_message, :body),
        subject:      params.dig(:customer_message, :subject),
        internal_only: false
      )

      if @new_message.save
        redirect_to customer_portal_messages_path, notice: "Message sent."
      else
        @messages = current_customer.customer_messages.visible_to_portal.recent
        render :index, status: :unprocessable_entity
      end
    end
  end
end
