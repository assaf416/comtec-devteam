# frozen_string_literal: true

Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.base_controller_class = [ "ActionController::Base", "ActionController::API" ]

  config.lograge.custom_options = lambda do |event|
    {
      timestamp:      Time.current.iso8601(3),
      service:        "devteam-hub",
      environment:    Rails.env,
      host:           Socket.gethostname,
      version:        ENV.fetch("APP_VERSION", "dev"),
      correlation_id: event.payload[:correlation_id],
      request_id:     event.payload[:request_id],
      user_id:        event.payload[:user_id],
      ip:             event.payload[:ip]
    }
  end

  config.lograge.custom_payload do |controller|
    {
      correlation_id: controller.request.headers["X-Correlation-ID"] || controller.request.request_id,
      request_id:     controller.request.request_id,
      user_id:        controller.try(:current_user)&.id,
      ip:             controller.request.remote_ip
    }
  end
end
