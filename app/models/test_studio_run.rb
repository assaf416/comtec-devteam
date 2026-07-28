# A single execution of one Cucumber feature file, triggered from the Test
# Studio pages (app/controllers/test_studio_controller.rb). Distinct from
# CiRun/TestResult, which track external projects' CI and require a project_id
# — this app itself isn't one of those Project records.
class TestStudioRun < ApplicationRecord
  belongs_to :triggered_by, class_name: "User", optional: true

  enum :status, { queued: 0, running: 1, passed: 2, failed: 3, error: 4 }, default: :queued

  # Skip broadcasts when seeding in bulk — there are no live subscribers and
  # no request context to render the partial against (mirrors ChatMessage).
  cattr_accessor :skip_broadcasts, default: false

  after_update_commit :broadcast_status
  after_update_commit :broadcast_output

  # Kept in sync with TestStudioHelper#test_studio_badge_id.
  def dom_badge_id
    "run_badge_#{feature_path.parameterize}"
  end

  # The edit page's live output panel for this feature file's runs.
  def dom_output_id
    "run_output_#{feature_path.parameterize}"
  end

  private

  def broadcast_status
    return if self.class.skip_broadcasts

    broadcast_replace_to(
      :test_studio,
      target: dom_badge_id,
      partial: "test_studio/run_badge",
      locals: { run: self, path: feature_path }
    )
  end

  def broadcast_output
    return if self.class.skip_broadcasts

    broadcast_replace_to(
      :test_studio,
      target: dom_output_id,
      partial: "test_studio/run_output",
      locals: { run: self, path: feature_path }
    )
  end
end
