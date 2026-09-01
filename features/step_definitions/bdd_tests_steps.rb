require "rails_helper"

Given("קיים פרויקט מסוג חבילת בדיקות בשם {string} עם תיקיית בית תקינה") do |name|
  @bdd_project = Project.create!(
    name: name, project_kind: :test_suite,
    home_folder: Rails.root.join("demo_bdd_projects/webservices_demo").to_s,
    cucumber_cmd: "bundle exec cucumber --no-profile"
  )
end

When("אני מייבא בדיקות עבור {string}") do |project_name|
  project = Project.find_by!(name: project_name)
  BddTestImportService.new(project).call
end

Given("קיימת בדיקת BDD מיובאת עבור {string}") do |project_name|
  project = Project.find_by!(name: project_name)
  BddTestImportService.new(project).call
  @bdd_test = project.bdd_tests.first
end

When("אני מריץ אותה") do
  visit bdd_test_path(@bdd_test)
  click_button "Run"
end

Then("אני אמור לראות בדיקת BDD משויכת ל{string} עם תגית {string}") do |project_name, tag|
  visit bdd_tests_path
  project = Project.find_by!(name: project_name)
  expect(page).to have_content(project.name)
  bdd_test = project.bdd_tests.first
  expect(bdd_test.tag_list).to include(tag)
  expect(page).to have_content(tag)
end

