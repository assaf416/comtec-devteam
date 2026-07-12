# Release timeline: what's live in each environment right now, and one-click
# rollback to the previous successful release.
class ReleasesController < ApplicationController
  ORDER = Arel.sql("COALESCE(deployed_at, created_at) DESC")

  def index
    @environments = Deployment.distinct.pluck(:environment).compact.sort

    # Current live release per [environment, project] = latest succeeded.
    @live = @environments.index_with do |env|
      Deployment.succeeded.where(environment: env)
                .includes(:project, :deployed_by).order(ORDER)
                .group_by(&:project_id).map { |_pid, deps| deps.first }
                .sort_by { |d| d.project.name }
    end

    @timeline = Deployment.includes(:project, :deployed_by).order(ORDER).limit(40)
  end

  def rollback
    current = Deployment.find(params[:id])
    pivot   = current.deployed_at || current.created_at
    previous = Deployment.succeeded
                         .where(project_id: current.project_id, environment: current.environment)
                         .where.not(id: current.id)
                         .where("COALESCE(deployed_at, created_at) < ?", pivot)
                         .order(ORDER).first

    if previous.nil?
      redirect_to releases_path, alert: "No previous successful release for #{current.environment}/#{current.project.name}." and return
    end

    current.update(status: :rolled_back)
    Deployment.create!(
      project_id:  current.project_id,
      environment: current.environment,
      version:     previous.version,
      deploy_type: current.deploy_type,
      status:      :in_progress,
      deployed_by: current_user,
      deployed_at: Time.current,
      server_name: previous.server_name,
      server_id:   previous.server_id,
      server_os:   previous.server_os,
      ip_address:  previous.ip_address,
      notes:       "Rollback of #{current.version} → #{previous.version} by #{current_user.display_name}."
    )

    redirect_to releases_path,
                notice: "↩️ #{current.environment}/#{current.project.name}: rolling back #{current.version} → #{previous.version}."
  end
end
