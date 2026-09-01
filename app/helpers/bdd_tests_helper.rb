module BddTestsHelper
  # Must match BddTestRun#dom_badge_id so a Turbo Stream broadcast from a
  # completed run replaces the right badge, even for a bdd_test that's never
  # been run yet (and so has no BddTestRun to ask).
  def bdd_test_badge_id(bdd_test)
    "bdd_run_badge_#{bdd_test.id}"
  end

  def bdd_test_output_id(bdd_test)
    "bdd_run_output_#{bdd_test.id}"
  end
end
