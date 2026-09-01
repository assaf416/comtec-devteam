# One imported Cucumber .feature file belonging to a Project (either a real
# multi-language app or one of the test-only "project_kind: test_suite"
# projects — SOAP, E2E, AS400). Caches the latest run's status/timestamp for
# fast list rendering; the full result (including result_html) lives on
# BddTestRun (see #latest_bdd_test_run).
class BddTest < ApplicationRecord
  belongs_to :project
  belongs_to :latest_bdd_test_run, class_name: "BddTestRun", optional: true

  # Must be declared (and so registered as a before_destroy callback) before
  # `has_many :bdd_test_runs, dependent: :destroy` below: latest_bdd_test_run_id
  # points at one of the very rows that association is about to remove, and
  # before_destroy callbacks run in declaration order — this has to clear the
  # FK first or the dependent-destroy hits a constraint violation.
  before_destroy { update_column(:latest_bdd_test_run_id, nil) }

  has_many :bdd_test_runs, dependent: :destroy

  acts_as_taggable_on :tags

  validates :path, presence: true, uniqueness: { scope: :project_id }

  # True when this test's path resolves to somewhere inside its project's
  # home_folder — guards against a tampered/stale path escaping via "../..",
  # independent of whether home_folder itself is trusted (see
  # TestStudioController#safe_feature_path for the pattern this mirrors).
  def safe_path?
    return false if project.home_folder.blank? || path.blank?

    root     = File.expand_path(project.home_folder)
    resolved = File.expand_path(File.join(root, path))
    resolved.start_with?("#{root}/") && File.exist?(resolved)
  end

  def absolute_path
    File.join(project.home_folder, path)
  end
end
