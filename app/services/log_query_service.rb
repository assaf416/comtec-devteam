# Reads logs from the central Loki store for the web Log Viewer.
#
# Every application ships its logs to Loki in roughly the same JSON shape
# (timestamp, level, service, message, …). This service queries Loki, normalises
# each entry, and flags errors/exceptions so the UI can highlight them. It mirrors
# the Faraday-based style of the other integration services and degrades
# gracefully when Loki is unreachable (returns empty results + #available?).
class LogQueryService
  LOKI_URL     = ENV.fetch("LOKI_URL", "http://loki:3100")
  LOKI_TIMEOUT = 10

  # Selectable time windows for the viewer.
  RANGES = {
    "15m" => 15 * 60,
    "1h"  => 60 * 60,
    "6h"  => 6 * 60 * 60,
    "24h" => 24 * 60 * 60,
    "7d"  => 7 * 24 * 60 * 60
  }.freeze

  LEVELS = %w[error warn info debug].freeze

  # Patterns that mark a line as an exception even when the level label is absent.
  EXCEPTION_PATTERNS = /
    exception | traceback | stack\s?trace | panic: | segfault |
    \bfatal\b | unhandled | nullreference | nil:nilclass |
    undefined\smethod | \bat\s.+\(.+:\d+\) | \bcaused\sby\b
  /xi

  def initialize(base_url: LOKI_URL)
    @conn = Faraday.new(url: base_url) do |f|
      f.options.timeout      = LOKI_TIMEOUT
      f.options.open_timeout = 5
    end
  end

  # Returns true when Loki answers its readiness probe.
  def available?
    @conn.get("/ready").success?
  rescue Faraday::Error
    false
  end

  # The list of `service` label values known to Loki (for the filter dropdown).
  def services
    resp = @conn.get("/loki/api/v1/label/service/values")
    return [] unless resp.success?

    Array(JSON.parse(resp.body).dig("data")).sort
  rescue Faraday::Error, JSON::ParserError
    []
  end

  # Query log entries. Returns an Array of normalised hashes, oldest → newest.
  def query(service: nil, level: nil, search: nil, range: "1h", limit: 300)
    seconds   = RANGES[range] || RANGES["1h"]
    end_ns    = (Time.now.to_f * 1e9).to_i
    start_ns  = ((Time.now.to_f - seconds) * 1e9).to_i

    params = {
      query: build_logql(service: service, level: level, search: search),
      start: start_ns.to_s,
      end:   end_ns.to_s,
      limit: [ limit.to_i, 2000 ].min,
      direction: "backward"
    }

    resp = @conn.get("/loki/api/v1/query_range", params)
    return [] unless resp.success?

    parse_entries(JSON.parse(resp.body)).sort_by { |e| e[:time] }
  rescue Faraday::Error, JSON::ParserError
    []
  end

  private

  def build_logql(service:, level:, search:)
    labels = []
    labels << %(service="#{sanitize_label(service)}") if service.present?
    labels << %(level="#{sanitize_label(level)}")     if level.present?
    selector = "{#{labels.join(',')}}"
    selector = '{service=~".+"}' if labels.empty? # Loki needs at least one matcher
    search.present? ? "#{selector} |= `#{search.to_s.gsub('`', "'")}`" : selector
  end

  def sanitize_label(value)
    value.to_s.gsub(/[^a-zA-Z0-9_\-.]/, "")
  end

  def parse_entries(body)
    results = body.dig("data", "result") || []
    results.flat_map do |stream|
      labels = stream["stream"] || {}
      (stream["values"] || []).map do |ts, line|
        normalize(ts, line, labels)
      end
    end
  end

  def normalize(ts_ns, line, labels)
    parsed = begin
      JSON.parse(line)
    rescue JSON::ParserError
      {}
    end

    time    = Time.at(ts_ns.to_f / 1e9).utc
    level   = normalize_level(parsed["level"] || parsed["severity"] || labels["level"])
    message = parsed["message"] || parsed["msg"] || parsed["log"] || line

    {
      time:        time,
      timestamp:   time.iso8601(3),
      level:       level,
      service:     labels["service"] || parsed["service"] || "unknown",
      environment: labels["environment"] || parsed["environment"],
      message:     message.to_s,
      exception:   exception?(level, message.to_s),
      raw:         parsed.presence || { "message" => line }
    }
  end

  def normalize_level(value)
    case value.to_s.downcase
    when "error", "err", "fatal", "critical", "crit" then "error"
    when "warn", "warning"                            then "warn"
    when "info", "notice"                             then "info"
    when "debug", "trace", "verbose"                  then "debug"
    else "other"
    end
  end

  def exception?(level, message)
    level == "error" || message.match?(EXCEPTION_PATTERNS)
  end
end
