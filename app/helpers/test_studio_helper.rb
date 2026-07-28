module TestStudioHelper
  # Must match TestStudioRun#dom_badge_id so Turbo Stream broadcasts from a
  # completed run replace the right badge on the index page, even for rows
  # that have never been run yet (and so have no TestStudioRun to ask).
  def test_studio_badge_id(path)
    "run_badge_#{path.parameterize}"
  end

  # Must match TestStudioRun#dom_output_id, for the same reason.
  def test_studio_output_id(path)
    "run_output_#{path.parameterize}"
  end
end
