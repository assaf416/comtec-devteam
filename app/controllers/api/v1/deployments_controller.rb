module Api
  module V1
    class DeploymentsController < BaseController
      before_action :set_deployment, only: %i[show update]

      def index
        scope = Deployment.includes(:project, :deployed_by, :client_account)
        scope = scope.where(project_id: params[:project_id]) if params[:project_id].present?
        scope = scope.where(environment: params[:environment]) if params[:environment].present?
        scope = scope.where(status: params[:status]) if params[:status].present?

        deployments = scope.order(created_at: :desc).limit(100)
        render json: deployments.map { |deployment| render_deployment(deployment) }
      end

      def show
        render json: render_deployment(@deployment)
      end

      def create
        attrs = deployment_attributes
        project = Project.find_by(id: attrs[:project_id])
        return render json: { error: "Project not found" }, status: :not_found unless project

        deployment = project.deployments.new(attrs.except(:project_id))
        deployment.deployed_by = current_api_user
        deployment.deployed_at ||= Time.current

        if deployment.save
          render json: render_deployment(deployment), status: :created
        else
          render json: { errors: deployment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @deployment.update(deployment_attributes.except(:project_id))
          render json: render_deployment(@deployment)
        else
          render json: { errors: @deployment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_deployment
        @deployment = Deployment.includes(:project, :deployed_by, :client_account).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Deployment not found" }, status: :not_found
      end

      def deployment_attributes
        attrs = params.require(:deployment).permit(
          :project_id, :version, :environment, :status, :machine_name,
          :client_account_id, :deploy_type, :notes, :deployed_at,
          env_vars: %i[key value]
        ).to_h
        attrs["env_vars"] = normalized_env_vars(attrs["env_vars"])
        attrs
      end
    end
  end
end
