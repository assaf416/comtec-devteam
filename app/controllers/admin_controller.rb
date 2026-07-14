class AdminController < ApplicationController
  before_action :require_admin!

  def users
    @users = User.order(:name)
  end

  def client_accounts
  end

  def settings
  end

  # Block a user so they can no longer sign in. Admins cannot block themselves.
  def block_user
    user = User.find(params[:id])
    if user == current_user
      redirect_to admin_users_path, alert: t("admin.users_page.cannot_block_self")
    else
      user.update!(blocked: true)
      redirect_to admin_users_path, notice: t("admin.users_page.blocked_notice", name: user.display_name)
    end
  end

  # Lift a block so the user can sign in again.
  def unblock_user
    user = User.find(params[:id])
    user.update!(blocked: false)
    redirect_to admin_users_path, notice: t("admin.users_page.unblocked_notice", name: user.display_name)
  end

  private

  def require_admin!
    return if current_user&.admin?

    redirect_to today_path, alert: t("admin.not_authorized")
  end
end
