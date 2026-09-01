require "rails_helper"

When("אני מבקר בדף רשימת הפרויקטים") do
  visit projects_path
end

Then("אני אמור לראות תגית סטטוס {string} ליד {string}") do |status, project_name|
  row = find(:xpath, "//tr[contains(., \"#{project_name}\")]")
  expect(row).to have_css(".badge", text: status)
end
