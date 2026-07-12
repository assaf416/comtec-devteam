module Api
  module V1
    class PullRequestsController < BaseController
      before_action :set_pull_request, only: :show

      def index
        scope = PullRequest.includes(:project, :ticket)
        scope = scope.where(project_id: params[:project_id]) if params[:project_id].present?
        scope = scope.where(ticket_id: params[:ticket_id]) if params[:ticket_id].present?
        scope = scope.where(status: params[:status]) if params[:status].present?

        pull_requests = scope.order(updated_at: :desc).limit(100)
        render json: pull_requests.map { |pull_request| render_pull_request(pull_request) }
      end

      def show
        render json: render_pull_request(@pull_request)
      end

      def create
        attrs = params.require(:pull_request).permit(:project_id, :ticket_id, :title, :description, :source_branch, :base_branch)

        ticket = Ticket.find_by(id: attrs[:ticket_id]) if attrs[:ticket_id].present?
        return render json: { error: "ticket_id is required" }, status: :unprocessable_entity unless ticket

        project = ticket&.project || Project.find_by(id: attrs[:project_id])
        return render json: { error: "Project not found" }, status: :not_found unless project

        owner, repo = GiteaService.repo_parts(project.repo_url)
        return render json: { error: "Project repo_url is not configured for pull request generation" }, status: :unprocessable_entity unless owner && repo

        source_branch = attrs[:source_branch].presence || ticket&.branch_name
        return render json: { error: "source_branch is required" }, status: :unprocessable_entity if source_branch.blank?

        title = attrs[:title].presence || ticket&.title
        return render json: { error: "title is required" }, status: :unprocessable_entity if title.blank?

        base_branch = attrs[:base_branch].presence || project.default_branch.presence || "main"
        response = GiteaService.new.create_pull_request(
          repo_owner: owner,
          repo_name: repo,
          title: title,
          head: source_branch,
          base: base_branch,
          body: attrs[:description].presence || ticket&.description
        )

        return render json: { error: "Pull request generation failed" }, status: :bad_gateway unless response

        pull_request = project.pull_requests.new(
          ticket: ticket,
          title: title,
          description: attrs[:description].presence || ticket&.description,
          pr_number: response["number"],
          author: current_api_user.display_name,
          gitea_url: response["html_url"] || response["url"],
          status: :open
        )

        if pull_request.save
          ticket&.update(pr_number: pull_request.pr_number, pr_url: pull_request.gitea_url)
          render json: render_pull_request(pull_request), status: :created
        else
          render json: { errors: pull_request.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_pull_request
        @pull_request = PullRequest.includes(:project, :ticket).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Pull request not found" }, status: :not_found
      end
    end
  end
end
