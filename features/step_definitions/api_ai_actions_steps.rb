require "rails_helper"
require "rack/test"

# Perform a token-authenticated API call against the app (no live server).
def api_call(method, path, params = {})
  session = Rack::Test::Session.new(Rails.application)
  session.public_send(method, path, params, { "HTTP_AUTHORIZATION" => "Bearer #{@api_token}" })
  @api_status = session.last_response.status
  @api_json = begin
    JSON.parse(session.last_response.body)
  rescue StandardError
    {}
  end
end

# ── Users ──────────────────────────────────────────────────────────────────
When("אני יוצר משתמש דרך ה-API בשם {string} ואימייל {string}") do |name, email|
  api_call(:post, "/api/v1/users", { name: name, email: email, role: "developer", phone: "050-0000000" })
end

Then("אמור להתקיים משתמש עם אימייל {string}") do |email|
  expect(User.find_by(email: email)).to be_present
end

Given("קיים משתמש עם אימייל {string}") do |email|
  FactoryBot.create(:user, email: email)
end

# ── Projects ───────────────────────────────────────────────────────────────
When("אני יוצר פרויקט דרך ה-API בשם {string} עם כתובת {string}") do |name, url|
  api_call(:post, "/api/v1/projects", { name: name, github_url: url })
end

Then("אמור להתקיים פרויקט בשם {string}") do |name|
  expect(Project.find_by(name: name)).to be_present
end

When("אני מוסיף דרך ה-API את המשתמש {string} לפרויקט {string}") do |email, project_name|
  project = Project.find_by!(name: project_name)
  api_call(:post, "/api/v1/projects/#{project.id}/add_member", { email: email, role: "developer" })
end

Then("המשתמש {string} אמור להיות חבר בפרויקט {string}") do |email, project_name|
  project = Project.find_by!(name: project_name)
  expect(project.members.exists?(email: email)).to be true
end

# ── Tickets ────────────────────────────────────────────────────────────────
When("אני יוצר טיקט דרך ה-API בשם {string} בפרויקט {string}") do |title, project_name|
  project = Project.find_by!(name: project_name)
  api_call(:post, "/api/v1/tickets", { project_id: project.id, title: title })
end

Then("אמור להתקיים טיקט {string} בפרויקט {string}") do |title, project_name|
  project = Project.find_by!(name: project_name)
  expect(project.tickets.find_by(title: title)).to be_present
end

When("אני מעדכן דרך ה-API את סטטוס הטיקט {string} ל-{string}") do |title, status|
  ticket = Ticket.find_by!(title: title)
  api_call(:patch, "/api/v1/tickets/#{ticket.id}", { status: status })
end

Then("סטטוס הטיקט {string} הוא {string}") do |title, status|
  expect(Ticket.find_by!(title: title).status).to eq(status)
end

When("אני משייך דרך ה-API את הטיקט {string} למשתמש {string}") do |title, email|
  ticket = Ticket.find_by!(title: title)
  user   = User.find_by!(email: email)
  api_call(:patch, "/api/v1/tickets/#{ticket.id}", { assignee_id: user.id })
end

Then("הטיקט {string} משויך ל-{string}") do |title, email|
  expect(Ticket.find_by!(title: title).assignee&.email).to eq(email)
end

# ── Documents (attachments) ────────────────────────────────────────────────
When("אני מעלה דרך ה-API את המסמך {string} לפרויקט {string}") do |filename, project_name|
  project = Project.find_by!(name: project_name)
  file    = Rack::Test::UploadedFile.new(fixture_file(filename), "text/plain")
  api_call(:post, "/api/v1/attachments", { project_id: project.id, file: file })
end

Then("קישור ההורדה בתגובה הוא נתיב יחסי") do
  expect(@api_json["download_url"]).to be_present
  expect(@api_json["download_url"]).to start_with("/")
end
