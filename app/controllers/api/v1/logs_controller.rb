# frozen_string_literal: true

module Api
  module V1
    class LogsController < BaseController
      LOKI_URL = ENV.fetch("LOKI_URL", "http://loki:3100")
      LOKI_TIMEOUT = 10

      # GET /api/v1/logs
      def index
        query = build_logql_query
        response = loki_query_range(
          query,
          start_time: params[:from],
          end_time:   params[:to],
          limit:      [ params.fetch(:limit, 100).to_i, 1000 ].min
        )
        render json: response
      end

      # GET /api/v1/logs/services
      def services
        labels = loki_label_values("service")
        render json: { services: labels }
      end

      # POST /api/v1/logs/push
      def push
        entries = params.require(:entries)
        streams = build_loki_streams(entries)
        push_to_loki(streams)
        render json: { accepted: entries.size, rejected: 0 }
      rescue ActionController::ParameterMissing => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue StandardError => e
        render json: { error: "Failed to push logs: #{e.message}" }, status: :bad_gateway
      end

      # GET /api/v1/logs/stats
      def stats
        render json: {
          error_count_24h:   loki_count('{level="error"}', "24h"),
          warn_count_24h:    loki_count('{level="warn"}',  "24h"),
          volume_by_service: loki_volume_by_label("service", "24h")
        }
      end

      private

      def build_logql_query
        labels = []
        labels << %Q(service="#{sanitize_label(params[:service])}") if params[:service].present?
        labels << %Q(level="#{sanitize_label(params[:level])}")     if params[:level].present?
        selector = "{#{labels.join(',')}}"
        params[:query].present? ? "#{selector} |= `#{sanitize_query(params[:query])}`" : selector
      end

      def sanitize_label(value)
        value.to_s.gsub(/[^a-zA-Z0-9_\-.]/, "")
      end

      def sanitize_query(value)
        value.to_s.gsub("`", "'")
      end

      def loki_query_range(query, start_time:, end_time:, limit:)
        uri = URI("#{LOKI_URL}/loki/api/v1/query_range")
        query_params = { query: query, limit: limit }
        query_params[:start] = start_time if start_time.present?
        query_params[:end]   = end_time   if end_time.present?
        uri.query = URI.encode_www_form(query_params)

        resp = loki_get(uri)
        parse_query_response(resp)
      end

      def loki_label_values(label)
        uri = URI("#{LOKI_URL}/loki/api/v1/label/#{label}/values")
        resp = loki_get(uri)
        data = JSON.parse(resp.body)
        data.dig("data") || []
      rescue StandardError
        []
      end

      def loki_count(selector, range)
        uri = URI("#{LOKI_URL}/loki/api/v1/query")
        uri.query = URI.encode_www_form(query: "count_over_time(#{selector} [#{range}])")
        resp = loki_get(uri)
        data = JSON.parse(resp.body)
        results = data.dig("data", "result") || []
        results.sum { |r| r.dig("value", 1).to_i }
      rescue StandardError
        0
      end

      def loki_volume_by_label(label, range)
        uri = URI("#{LOKI_URL}/loki/api/v1/label/#{label}/values")
        resp = loki_get(uri)
        services = JSON.parse(resp.body).dig("data") || []
        services.each_with_object({}) do |svc, hash|
          hash[svc] = loki_count(%Q({#{label}="#{svc}"}), range)
        end
      rescue StandardError
        {}
      end

      def build_loki_streams(entries)
        entries.group_by { |e| e[:service] || e["service"] }.map do |svc, logs|
          {
            stream: {
              service:     sanitize_label(svc),
              environment: sanitize_label(logs.first[:environment] || logs.first["environment"] || Rails.env)
            },
            values: logs.map do |l|
              ts = begin
                     (Time.parse(l[:timestamp] || l["timestamp"]).to_f * 1e9).to_i.to_s
                   rescue StandardError
                     (Time.current.to_f * 1e9).to_i.to_s
                   end
              [ ts, l.to_json ]
            end
          }
        end
      end

      def push_to_loki(streams)
        uri = URI("#{LOKI_URL}/loki/api/v1/push")
        http = Net::HTTP.new(uri.hostname, uri.port)
        http.open_timeout = LOKI_TIMEOUT
        http.read_timeout = LOKI_TIMEOUT
        req = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
        req.body = { streams: streams }.to_json
        http.request(req)
      end

      def loki_get(uri)
        http = Net::HTTP.new(uri.hostname, uri.port)
        http.open_timeout = LOKI_TIMEOUT
        http.read_timeout = LOKI_TIMEOUT
        http.get(uri.request_uri)
      end

      def parse_query_response(resp)
        data = JSON.parse(resp.body)
        results = data.dig("data", "result") || []
        entries = results.flat_map do |stream|
          (stream["values"] || []).map do |ts, line|
            parsed = begin
                       JSON.parse(line)
                     rescue StandardError
                       { "message" => line }
                     end
            parsed.merge("timestamp" => Time.at(ts.to_f / 1e9).utc.iso8601(3))
          end
        end
        { logs: entries, total: entries.size, has_more: false }
      rescue JSON::ParserError
        { logs: [], total: 0, has_more: false }
      end
    end
  end
end
