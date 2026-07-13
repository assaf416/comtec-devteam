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

      # Create a user (name, role, email, phone, avatar image). A random password
      # is generated since the AI provisions the account.
      def create
        user = User.new(
          name:     params[:name],
          email:    params[:email],
          role:     params[:role].presence || "developer",
          phone:    params[:phone],
          password: params[:password].presence || SecureRandom.base58(16)
        )
        user.avatar.attach(params[:avatar]) if params[:avatar].present?

        if user.save
          render json: render_user(user), status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
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
