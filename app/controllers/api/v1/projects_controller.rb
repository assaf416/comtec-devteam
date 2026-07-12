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
    end
  end
end
