# Web UI for reading application logs from the central Loki store in a readable,
# colour-highlighted format. `index` renders the full page; `tail` returns just
# the rendered log lines so the Stimulus controller can poll for a live "watch".
class LogViewerController < ApplicationController
  def index
    @service_options = log_service.services
    @entries         = fetch_entries
    @available       = log_service.available? || @entries.any?
    @error_count     = @entries.count { |e| e[:level] == "error" || e[:exception] }
    @warn_count      = @entries.count { |e| e[:level] == "warn" }
  end

  # Polled by the live-watch Stimulus controller; returns only the log lines.
  def tail
    @entries = fetch_entries
    render partial: "log_viewer/lines", locals: { entries: @entries }, layout: false
  end

  private

  def log_service
    @log_service ||= LogQueryService.new
  end

  def fetch_entries
    log_service.query(
      service: params[:service].presence,
      level:   params[:level].presence,
      search:  params[:search].presence,
      range:   params[:range].presence_in(LogQueryService::RANGES.keys) || "1h",
      limit:   (params[:limit] || 300).to_i
    )
  end
end
