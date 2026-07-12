module Api
  module V1
    class CiRunsController < BaseController
      before_action :set_ci_run, only: :show

      def index
        scope = CiRun.includes(:project, :ticket, :triggered_by, :test_results)
        scope = scope.where(project_id: params[:project_id]) if params[:project_id].present?
        scope = scope.where(ticket_id: params[:ticket_id]) if params[:ticket_id].present?
        scope = scope.where(status: params[:status]) if params[:status].present?

        ci_runs = scope.order(created_at: :desc).limit(100)
        render json: ci_runs.map { |ci_run| render_ci_run(ci_run) }
      end

      def show
        render json: render_ci_run(@ci_run)
      end

      def create
        attrs = params.require(:ci_run).permit(:project_id, :ticket_id, :job_name, :branch_name, :commit_sha)
        ticket = Ticket.find_by(id: attrs[:ticket_id]) if attrs[:ticket_id].present?
        project = ticket&.project || Project.find_by(id: attrs[:project_id])
        return render json: { error: "Project not found" }, status: :not_found unless project

        job_name = attrs[:job_name].presence || project.name.parameterize
        branch_name = attrs[:branch_name].presence || ticket&.branch_name || project.default_branch.presence || "main"

        build_requested = JenkinsService.new.trigger_build(
          job_name: job_name,
          params: {
            project_id: project.id,
            ticket_id: ticket&.id,
            branch_name: branch_name,
            commit_sha: attrs[:commit_sha]
          }.compact
        )

        return render json: { error: "Test run could not be started" }, status: :bad_gateway unless build_requested

        ci_run = project.ci_runs.new(
          ticket: ticket,
          triggered_by: current_api_user,
          build_number: "queued-#{SecureRandom.hex(6)}",
          status: :pending,
          branch_name: branch_name,
          commit_sha: attrs[:commit_sha],
          started_at: Time.current,
          log_url: "#{JenkinsService::BASE_URL}/job/#{job_name}/"
        )

        if ci_run.save
          render json: render_ci_run(ci_run).merge(job_name: job_name), status: :created
        else
          render json: { errors: ci_run.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_ci_run
        @ci_run = CiRun.includes(:project, :ticket, :triggered_by, :test_results).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "CI run not found" }, status: :not_found
      end
    end
  end
end
