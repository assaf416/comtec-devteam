require "rails_helper"

Given("לפרויקט {string} יש חבר צוות בשם {string}") do |project_name, member_name|
  project = Project.find_by!(name: project_name)
  member = FactoryBot.create(:user, name: member_name)
  ProjectMembership.create!(project: project, user: member, role: :developer)
  @member_name = member_name
end

When("אני מבקר בדף רשימת הפרויקטים") do
  visit projects_path
end

Then("אני אמור לראות אייקון חבר צוות עבור {string} ליד {string}") do |member_name, project_name|
  row = find(:xpath, "//tr[contains(., \"#{project_name}\")]")
  expect(row).to have_css(".avatar-stack[title*='#{member_name}']")
end
