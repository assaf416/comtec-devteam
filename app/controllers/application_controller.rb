class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_locale
  before_action :set_notification_count
  before_action :load_sidebar_data, if: :user_signed_in?

  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  allow_browser versions: :modern

  private

  def set_locale
    locale = params[:locale] || current_user&.preferred_language || I18n.default_locale
    I18n.locale = locale.to_sym if I18n.available_locales.include?(locale.to_sym)
  end

  def set_notification_count
    @unread_notification_count = current_user&.notifications&.where(read_at: nil)&.count || 0
  end

  def load_sidebar_data
    # Active projects for sidebar list
    @sidebar_projects = Project.active.order(:name)

    # Latest CI run per project for status dot
    latest_ci_ids = CiRun.select("MAX(id) as id").group(:project_id).map(&:id)
    @sidebar_latest_ci = CiRun.where(id: latest_ci_ids).index_by(&:project_id)

    # Team members for sidebar presence list
    @sidebar_team_members = User.order(:name)

    # Right panel: 15 most recent notifications
    @panel_notifications = current_user.notifications
                                       .order(created_at: :desc)
                                       .limit(15)

    # Right panel: recent CI runs + deployments combined into activity feed
    recent_ci      = CiRun.includes(:project).order(updated_at: :desc).limit(8)
    recent_deploys = Deployment.includes(:project).order(updated_at: :desc).limit(8)

    @panel_activity = (
      recent_ci.map      { |r| { type: :ci,     obj: r, at: r.updated_at } } +
      recent_deploys.map { |d| { type: :deploy,  obj: d, at: d.updated_at } }
    ).sort_by { |e| -e[:at].to_i }.first(15)
  end

  def user_not_authorized
    flash[:alert] = t("errors.not_authorized")
    redirect_back(fallback_location: root_path)
  end

  def after_sign_in_path_for(resource)
    case resource
    when CustomerUser then customer_portal_root_path
    else today_path
    end
  end
end
