module CustomerPortal
  class SessionsController < Devise::SessionsController
    layout "customer_portal"

    # Skip the internal-user authentication check
    skip_before_action :authenticate_user!, raise: false
    skip_before_action :set_notification_count, raise: false

    def after_sign_out_path_for(_resource_or_scope)
      new_customer_user_session_path
    end
  end
end
