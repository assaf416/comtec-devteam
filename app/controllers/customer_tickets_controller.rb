class CustomerTicketsController < ApplicationController
  before_action :set_customer
  before_action :set_ticket, only: %i[show edit update destroy resolve link_ticket]

  def index
    @customer_tickets = @customer.customer_tickets.includes(:assigned_to, :internal_ticket)
    @customer_tickets = @customer_tickets.where(status: params[:status]) if params[:status].present?
    @customer_tickets = @customer_tickets.order(created_at: :desc)
  end

  def show; end

  def new
    @customer_ticket = @customer.customer_tickets.build
  end

  def create
    @customer_ticket = @customer.customer_tickets.build(ticket_params)
    if @customer_ticket.save
      redirect_to customer_customer_ticket_path(@customer, @customer_ticket), notice: t("customer_tickets.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @customer_ticket.update(ticket_params)
      redirect_to customer_customer_ticket_path(@customer, @customer_ticket), notice: t("customer_tickets.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @customer_ticket.destroy
    redirect_to customer_customer_tickets_path(@customer), notice: t("customer_tickets.destroyed")
  end

  def resolve
    @customer_ticket.resolve!
    redirect_to customer_customer_ticket_path(@customer, @customer_ticket), notice: t("customer_tickets.resolved")
  end

  def link_ticket
    internal = Ticket.find(params[:internal_ticket_id])
    @customer_ticket.link_to_internal!(internal)
    redirect_to customer_customer_ticket_path(@customer, @customer_ticket), notice: t("customer_tickets.linked")
  end

  private

  def set_customer
    @customer = Customer.find(params[:customer_id])
  end

  def set_ticket
    @customer_ticket = @customer.customer_tickets.find(params[:id])
  end

  def ticket_params
    params.require(:customer_ticket).permit(:title, :body, :status, :priority, :assigned_to_id, :internal_ticket_id)
  end
end
