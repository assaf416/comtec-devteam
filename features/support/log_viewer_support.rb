# Stubs LogQueryService for the cucumber suite so the Log Viewer can be tested
# without a running Loki server. Tests control the canned entries / availability
# through class accessors. Loaded only under features/.

require Rails.root.join("app/services/log_query_service").to_s

class LogQueryService
  class << self
    attr_accessor :test_entries, :test_available, :test_services
  end

  def available?
    self.class.test_available.nil? ? true : self.class.test_available
  end

  def services
    self.class.test_services || %w[payments-api web-app worker]
  end

  def query(service: nil, level: nil, search: nil, range: "1h", limit: 300)
    entries = self.class.test_entries || self.class.default_entries
    entries = entries.select { |e| e[:service] == service } if service.present?
    entries = entries.select { |e| e[:level] == level }     if level.present?
    entries = entries.select { |e| e[:message].include?(search) } if search.present?
    entries
  end

  def self.default_entries
    base = Time.utc(2026, 6, 5, 9, 0, 0)
    [
      { level: "info",  service: "web-app",      message: "GET /tickets 200 in 32ms" },
      { level: "debug", service: "worker",       message: "Enqueued SyncPullRequestJob" },
      { level: "warn",  service: "payments-api", message: "Retrying charge, attempt 2" },
      { level: "error", service: "payments-api", message: "Payment gateway timeout after 30s" },
      { level: "info",  service: "web-app",
        message: "NullReferenceException in OrderController.Checkout at Order.cs:42" }
    ].each_with_index.map do |e, i|
      time = base + i
      e.merge(
        time:        time,
        timestamp:   time.iso8601(3),
        environment: "production",
        exception:   e[:level] == "error" ||
                     e[:message].match?(LogQueryService::EXCEPTION_PATTERNS),
        raw:         { "message" => e[:message] }
      )
    end
  end
end

Before do
  LogQueryService.test_entries   = nil
  LogQueryService.test_available = true
  LogQueryService.test_services  = nil
end
