require "rails_helper"

Given("פתיחת issue ב-GitHub תצליח עם מספר {int} וקישור {string}") do |number, url|
  TicketGithubIssueService.test_result = { "number" => number, "html_url" => url }
end

Given("קיים טיקט {string} בפרויקט {string}") do |title, project_name|
  project = Project.find_by!(name: project_name)
  @ticket = FactoryBot.create(:ticket, project: project, title: title, owner: @user)
end

Given("קיים טיקט {string} בפרויקט {string} המשויך אליי") do |title, project_name|
  project = Project.find_by!(name: project_name)
  @ticket = FactoryBot.create(:ticket, project: project, title: title,
                              owner: @user, assignee: @user)
end

When("אני מבקר בטיקט {string}") do |title|
  ticket = Ticket.find_by!(title: title)
  visit ticket_path(ticket)
end

When("אני מבקש בצ'אט של {string} הערכת זמנים לטיקט {string}") do |project_name, title|
  project = Project.find_by!(name: project_name)
  ticket  = project.tickets.find_by!(title: title)
  ref     = ticket.github_issue_number || ticket.id
  @chat_result = Ai::ChatSkillRouter.new(project: project, user: @user)
                   .route("תן הערכת זמנים לטיקט ##{ref}")
end

Then("הסוכן אמור להחזיר תשובה") do
  expect(@chat_result.handled).to be true
  expect(@chat_result.reply).to be_present
end
