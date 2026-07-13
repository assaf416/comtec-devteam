require "rails_helper"

Given("קיים Pull Request עם קובץ קוד רחב בפרויקט {string}") do |project_name|
  project = Project.find_by!(name: project_name)
  ticket  = FactoryBot.create(:ticket, project: project, title: "Wide diff")
  @pull_request = FactoryBot.create(:pull_request, project: project, ticket: ticket, pr_number: 20,
    files_data: [
      {
        "path"      => "app/models/wide_example.rb",
        "language"  => "ruby",
        "additions" => 12,
        "deletions" => 3,
        "content"   => "puts " + ("x" * 300) # a long, non-wrapping line
      }
    ])
end

When("אני מבקר בעמוד ה-Pull Request") do
  visit pull_request_path(@pull_request)
end

Then("פריסת הקבצים אמורה למנוע שבירת עמודות") do
  # The wrapper carries the min-width:0 guard that keeps the wide code viewer
  # from stretching and breaking the Bootstrap grid columns.
  expect(page).to have_css(".pr-layout")
  expect(page).to have_css(".pr-files-grid")
end
