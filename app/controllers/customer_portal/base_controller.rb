module CustomerPortal
  class BaseController < ActionController::Base
    layout "customer_portal"

    protect_from_forgery with: :exception
    before_action :authenticate_customer_user!
    before_action :set_portal_locale

    allow_browser versions: :modern

    helper_method :current_customer

    private

    def current_customer
      @current_customer ||= current_customer_user&.customer
    end

    def set_portal_locale
      I18n.locale = I18n.default_locale
    end
  end
end
