require "rails_helper"

PASSING_STEP_REPORT = [
  {
    "name" => "Feature",
    "elements" => [
      {
        "keyword" => "תרחיש", "name" => "Scenario",
        "steps" => [
          { "keyword" => "בהינתן ", "name" => "משהו עבר", "status" => "passed", "error_message" => nil }
        ]
      }
    ]
  }
].freeze

FAILING_STEP_REPORT = [
  {
    "name" => "Feature",
    "elements" => [
      {
        "keyword" => "תרחיש", "name" => "Scenario",
        "steps" => [
          { "keyword" => "אז ", "name" => "משהו נכשל", "status" => "failed", "error_message" => "משהו השתבש" }
        ]
      }
    ]
  }
].freeze

Given("קיים דוח הרצה עבור {string} עם שלב שעבר") do |feature_path|
  TestStudioRun.create!(feature_path: feature_path, status: :passed, structured_results: PASSING_STEP_REPORT.to_json)
end

Given("קיים דוח הרצה עבור {string} עם שלב שנכשל") do |feature_path|
  TestStudioRun.create!(feature_path: feature_path, status: :failed, structured_results: FAILING_STEP_REPORT.to_json)
end

When("אני מבקר בעורך הבדיקות של הקובץ {string}") do |feature_path|
  visit edit_test_studio_test_path(path: feature_path)
end

Then("אני אמור לראות דוח שלבים עם שלב אחד לפחות בצבע ירוק") do
  expect(page).to have_css(".tsr-step-passed")
end

Then("אני אמור לראות שלב בצבע אדום עם הודעת שגיאה") do
  expect(page).to have_css(".tsr-step-failed")
  expect(page).to have_css(".tsr-error", text: "משהו השתבש")
end
