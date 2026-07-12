module Api
  module V1
    module CiRuns
      class TestResultsController < BaseController
        before_action :set_ci_run

        def index
          render json: @ci_run.test_results.order(:id).map { |result| render_test_result(result) }
        end

        def create
          attrs = params.require(:test_result).permit(:suite_name, :total, :passed, :failed, :skipped, :duration_ms, :xml_report)
          test_result = @ci_run.test_results.new(attrs)

          if test_result.save
            @ci_run.update(
              status: test_result.failed.to_i.positive? ? :failed : :passed,
              finished_at: @ci_run.finished_at || Time.current
            )
            render json: render_test_result(test_result), status: :created
          else
            render json: { errors: test_result.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def set_ci_run
          @ci_run = ::CiRun.find(params[:ci_run_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "CI run not found" }, status: :not_found
        end
      end
    end
  end
end
