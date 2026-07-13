require "rails_helper"

Given("קיים פרויקט {string} עם {int} חברי צוות") do |name, count|
  @project = FactoryBot.create(:project, name: name, active: true)
  count.times do |i|
    user = FactoryBot.create(:user, name: "חבר צוות #{i + 1}")
    @project.project_memberships.create!(user: user, role: :developer)
  end
end

Then("אני אמור לראות סרגל אווטרים של חברי הצוות") do
  expect(page).to have_css(".avatar-stack .avatar-stack-item", minimum: 1)
end
