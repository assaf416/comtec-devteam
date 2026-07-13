module Api
  module V1
    class ProjectsController < BaseController
      def index
        projects = current_api_user.member_projects.includes(:tickets).order(:name)
        render json: projects.map { |p|
          {
            id:             p.id,
            name:           p.name,
            repo_url:       p.repo_url,
            default_branch: p.default_branch,
            tech_stack:     p.tech_stack,
            active:         p.active,
            open_tickets:   p.tickets.where.not(status: %w[done cancelled]).count
          }
        }
      end

      def show
        project = current_api_user.member_projects.find(params[:id])
        render json: {
          id:             project.id,
          name:           project.name,
          repo_url:       project.repo_url,
          default_branch: project.default_branch,
          tech_stack:     project.tech_stack,
          members: project.members.order(:name).map { |u| { id: u.id, name: u.display_name, email: u.email } },
          tickets: project.tickets.where(assignee: current_api_user)
                          .order(updated_at: :desc)
                          .map { |t| render_ticket(t) }
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Project not found" }, status: :not_found
      end

      # Create a project (name, github url). The creator is added as a lead member.
      def create
        project = Project.new(
          name:     params[:name],
          repo_url: params[:github_url].presence || params[:repo_url]
        )

        if project.save
          project.project_memberships.create(user: current_api_user, role: :lead)
          render json: render_project(project), status: :created
        else
          render json: { errors: project.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Add a user to the project (by user_id or email), optionally with a role.
      def add_member
        project = Project.find_by(id: params[:id])
        return render json: { error: "Project not found" }, status: :not_found unless project

        user = User.find_by(id: params[:user_id]) || User.find_by(email: params[:email])
        return render json: { error: "User not found" }, status: :not_found unless user

        membership = project.project_memberships.find_or_initialize_by(user: user)
        was_new = membership.new_record?
        membership.role = params[:role] if params[:role].present?

        if membership.save
          render json: render_project(project), status: (was_new ? :created : :ok)
        else
          render json: { errors: membership.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
