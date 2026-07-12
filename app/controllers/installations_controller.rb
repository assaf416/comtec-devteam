class InstallationsController < ApplicationController
  before_action :set_customer
  before_action :set_installation, only: %i[show edit update destroy]

  def index
    @installations = @customer.installations.includes(:project, :deployment).order(installed_at: :desc)
    @installations = @installations.where(status: params[:status]) if params[:status].present?
    @installations = @installations.where(environment: params[:environment]) if params[:environment].present?
  end

  def show; end

  def new
    @installation = @customer.installations.build(installed_at: Time.current)
  end

  def create
    @installation = @customer.installations.build(installation_params)
    if @installation.save
      redirect_to customer_installation_path(@customer, @installation), notice: t("installations.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @installation.update(installation_params)
      redirect_to customer_installation_path(@customer, @installation), notice: t("installations.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @installation.destroy
    redirect_to customer_installations_path(@customer), notice: t("installations.destroyed")
  end

  private

  def set_customer
    @customer = Customer.find(params[:customer_id])
  end

  def set_installation
    @installation = @customer.installations.find(params[:id])
  end

  def installation_params
    params.require(:installation).permit(
      :software_name, :version, :environment, :status,
      :project_id, :deployment_id, :installed_at, :notes
    )
  end
end
