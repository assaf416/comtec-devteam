module CustomerPortal
  class TicketsController < BaseController
    before_action :set_ticket, only: %i[show]

    def index
      @type   = params[:type].presence_in(%w[support feature_request]) || "support"
      @status = params[:status]

      @tickets = current_customer.customer_tickets.where(ticket_type: @type)
      @tickets = @tickets.where(status: @status) if CustomerTicket.statuses.key?(@status)
      @tickets = @tickets.order(updated_at: :desc)
    end

    def show; end

    def new
      @type   = params[:type].presence_in(%w[support feature_request]) || "support"
      @ticket = CustomerTicket.new(ticket_type: @type)
    end

    def create
      @ticket = current_customer.customer_tickets.new(ticket_params)
      if @ticket.save
        redirect_to customer_portal_ticket_path(@ticket),
                    notice: "Your #{@ticket.ticket_type_support? ? 'ticket' : 'story'} was submitted successfully."
      else
        @type = @ticket.ticket_type
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_ticket
      @ticket = current_customer.customer_tickets.find(params[:id])
    end

    def ticket_params
      params.require(:customer_ticket).permit(:title, :body, :priority, :ticket_type)
    end
  end
end
