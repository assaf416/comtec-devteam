class DeploymentsController < ApplicationController
  before_action :set_project, only: %i[index new create]
  before_action :set_deployment, only: %i[show edit update destroy]

  def index
    @deployments = @project.deployments
                            .includes(:deployed_by, :client_account)
                            .order(created_at: :desc)
    @deployments = @deployments.where(environment: params[:environment]) if params[:environment].present?
    @deployments = @deployments.where(status: params[:status]) if params[:status].present?
  end

  def show; end

  def new
    @deployment = @project.deployments.build(deployed_by: current_user)
    @client_accounts = ClientAccount.order(:name)
  end

  def create
    @deployment = @project.deployments.build(deployment_params.merge(deployed_by: current_user, deployed_at: Time.current))
    if @deployment.save
      redirect_to @deployment, notice: "Deployment record created."
    else
      @client_accounts = ClientAccount.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @client_accounts = ClientAccount.order(:name)
  end

  def update
    if @deployment.update(deployment_params)
      redirect_to @deployment, notice: "Deployment updated."
    else
      @client_accounts = ClientAccount.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @deployment.destroy
    redirect_to project_deployments_path(@deployment.project), notice: "Deployment deleted."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_deployment
    @deployment = Deployment.find(params[:id])
    @project = @deployment.project
  end

  def deployment_params
    raw = params.require(:deployment).permit(
      :version, :environment, :status, :machine_name,
      :client_account_id, :deploy_type, :notes,
      env_vars: [ :key, :value ]
    )
    # Strip blank rows from env_vars
    raw[:env_vars] = Array(raw[:env_vars]).reject { |r| r[:key].blank? && r[:value].blank? } if raw.key?(:env_vars)
    raw
  end
end
