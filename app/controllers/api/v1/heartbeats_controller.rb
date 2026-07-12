# frozen_string_literal: true

module Api
  module V1
    # Heartbeat ingestion — each remote machine POSTs its OS telemetry here.
    #   POST /api/v1/heartbeats
    #   { ip_address, server_name, server_os, cpu, mem, disk, errors, log_file_url }
    class HeartbeatsController < BaseController
      def create
        beat = ServerHeartbeat.new(heartbeat_params)
        # Agents may send the error count as `errors`; map it to error_count.
        beat.error_count = params[:errors] if params.key?(:errors)
        beat.recorded_at ||= Time.current

        if beat.save
          render json: { ok: true, id: beat.id }, status: :created
        else
          render json: { ok: false, errors: beat.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def heartbeat_params
        params.permit(:ip_address, :server_name, :server_os, :cpu, :mem, :disk, :error_count, :log_file_url, :recorded_at)
      end
    end
  end
end
