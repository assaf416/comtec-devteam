# The Deploy console: pick a project + a CI image tag + a target server and
# roll it out through the external deploy backend (DeployService).
class DeployController < ApplicationController
  before_action :load_console, only: %i[index create]

  def index; end

  def create
    project = Project.find(params[:project_id])
    server  = ServerHeartbeat.for_ip(params[:server_ip]).recent.first
    image   = params[:image_tag].to_s.strip

    if image.blank? || params[:environment].blank?
      redirect_to deploy_path, alert: "Pick an image tag and an environment to deploy." and return
    end

    deployment = @deploy.deploy!(
      project:     project,
      image_tag:   image,
      environment: params[:environment],
      server:      server,
      user:        current_user
    )

    if deployment.persisted?
      target = server&.server_name || server&.ip_address || params[:environment]
      redirect_to deploy_path, notice: "🚀 #{image} → #{target}: deployment #{deployment.status.humanize.downcase}."
    else
      redirect_to deploy_path, alert: "Could not start deployment: #{deployment.errors.full_messages.to_sentence}"
    end
  end

  private

  def load_console
    @deploy  = DeployService.new
    @servers = ServerHeartbeat.servers.to_a
    @projects = Project.order(:name).to_a
    @recent_deployments = Deployment.includes(:project, :deployed_by)
                                    .order(created_at: :desc).limit(15)
    # Deployable image tags keyed by project id (for the form's dependent select).
    @tags_by_project = @projects.to_h { |p| [ p.id, @deploy.deployable_tags(p) ] }
  end
end
