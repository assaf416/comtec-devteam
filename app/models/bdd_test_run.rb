# A single execution of one BddTest, triggered from the BDD Tests pages
# (app/controllers/bdd_tests_controller.rb) via BddTestRunJob. Mirrors
# TestStudioRun's shape (status lifecycle, live Turbo broadcasts, structured
# step report) but for externally-checked-out, multi-language projects
# instead of this app's own internal suite.
class BddTestRun < ApplicationRecord
  belongs_to :bdd_test
  belongs_to :triggered_by, class_name: "User", optional: true

  enum :status, { queued: 0, running: 1, passed: 2, failed: 3, error: 4 }, default: :queued

  cattr_accessor :skip_broadcasts, default: false

  after_update_commit :broadcast_status
  after_update_commit :broadcast_output

  def dom_badge_id
    "bdd_run_badge_#{bdd_test_id}"
  end

  def dom_output_id
    "bdd_run_output_#{bdd_test_id}"
  end

  # Parsed structured_results (same shape as TestStudioRun#step_report — see
  # BddTestRunJob#parse_step_report) — nil while running / on error.
  def step_report
    return nil if structured_results.blank?

    JSON.parse(structured_results)
  rescue JSON::ParserError
    nil
  end

  private

  def broadcast_status
    return if self.class.skip_broadcasts

    broadcast_replace_to(
      :bdd_tests,
      target: dom_badge_id,
      partial: "bdd_tests/run_badge",
      locals: { run: self, bdd_test: bdd_test }
    )
  end

  def broadcast_output
    return if self.class.skip_broadcasts

    broadcast_replace_to(
      :bdd_tests,
      target: dom_output_id,
      partial: "bdd_tests/run_output",
      locals: { run: self, bdd_test: bdd_test }
    )
  end
end
