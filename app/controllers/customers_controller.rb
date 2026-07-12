class CustomersController < ApplicationController
  before_action :set_customer, only: %i[show edit update destroy]

  def index
    @customers = Customer.all.order(:name)
    @customers = @customers.active if params[:active_only] == "1"
    @customers = @customers.where("name LIKE ? OR company LIKE ? OR email LIKE ?",
                                  "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%") if params[:q].present?
  end

  def show
    @customer_tickets = @customer.customer_tickets.order(created_at: :desc)
    @installations    = @customer.installations.includes(:project, :deployment).order(installed_at: :desc)
  end

  def new
    @customer = Customer.new
  end

  def create
    @customer = Customer.new(customer_params)
    if @customer.save
      redirect_to @customer, notice: t("customers.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @customer.update(customer_params)
      redirect_to @customer, notice: t("customers.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @customer.destroy
    redirect_to customers_path, notice: t("customers.destroyed")
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(:name, :company, :email, :phone, :contact_person, :notes, :active)
  end
end
