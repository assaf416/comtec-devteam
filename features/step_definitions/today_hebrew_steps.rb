require "rails_helper"

Given("קיימת בקשת משיכה הממתינה לסקירה בפרויקט {string}") do |project_name|
  project = Project.find_by!(name: project_name)
  ticket = FactoryBot.create(:ticket, project: project)
  FactoryBot.create(:pull_request, project: project, ticket: ticket, status: :review, pr_number: 999, title: "בדיקה", author: "מישהו")
end
