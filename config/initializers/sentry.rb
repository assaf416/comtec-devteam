Sentry.init do |config|
  config.dsn = ENV.fetch("SENTRY_DSN", nil)
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]
  config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", "0.1").to_f
  config.environment = Rails.env

  # Don't send PII
  config.send_default_pii = false

  # Tag releases
  config.release = ENV.fetch("APP_VERSION", "unknown")
end
