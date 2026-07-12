module Api
  module V1
    class UsersController < BaseController
      def me
        render json: {
          id:         current_api_user.id,
          name:       current_api_user.display_name,
          email:      current_api_user.email,
          role:       current_api_user.role,
          api_token:  current_api_user.api_token,
          tickets:    current_api_user.assigned_tickets.where.not(status: :done).count,
          projects:   current_api_user.member_projects.pluck(:id, :name).map { |id, name| { id: id, name: name } }
        }
      end

      def token
        render json: { api_token: current_api_user.api_token }
      end

      def regenerate_token
        current_api_user.regenerate_api_token!
        render json: { api_token: current_api_user.api_token }
      end
    end
  end
end
