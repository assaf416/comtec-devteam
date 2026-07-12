class ProfileController < ApplicationController
  before_action :authenticate_user!

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if params[:user][:password].blank?
      # No password change — skip password fields
      result = @user.update(profile_params_without_password)
    else
      # Password change — require current_password via Devise
      result = @user.update_with_password(profile_params_with_password)
    end

    if result
      bypass_sign_in(@user) # keep session alive after password change
      I18n.locale = @user.preferred_language.to_sym
      redirect_to edit_profile_path, notice: t("profile.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params_without_password
    params.require(:user).permit(:name, :preferred_language, :avatar)
  end

  def profile_params_with_password
    params.require(:user).permit(:name, :preferred_language, :avatar,
                                 :current_password, :password, :password_confirmation)
  end
end
