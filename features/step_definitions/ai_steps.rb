# Steps for the AI Agent feature. The Ollama client is stubbed in
# features/support/ai_support.rb, so these exercise the full controller →
# service → AiReview flow without any real LLM.

# ── Setup ─────────────────────────────────────────────────────────────────────

Given("the local AI model is available") do
  Ai::OllamaClient.test_available = true
end

Given("the local AI model is offline") do
  Ai::OllamaClient.test_available = false
end

Given("the AI model will return verdict {string}") do |verdict|
  Ai::OllamaClient.test_response =
    "VERDICT: #{verdict}\nSCORE: 80\n\n## Notes\nStubbed response for tests."
end

Given("an AI project {string} with a ticket {string}") do |project_name, title|
  @project = FactoryBot.create(:project, name: project_name, active: true)
  @ticket  = FactoryBot.create(:ticket, project: @project, title: title)
end

Given("an AI project {string} with a ticket {string} owned by {string} and assigned to {string}") do |project_name, title, owner_name, assignee_name|
  @project  = FactoryBot.create(:project, name: project_name, active: true)
  @owner    = FactoryBot.create(:user, name: owner_name)
  @assignee = FactoryBot.create(:user, name: assignee_name)
  @ticket   = FactoryBot.create(:ticket, project: @project, title: title,
                                owner: @owner, assignee: @assignee)
end

Given("an AI project {string} with an active sprint {string}") do |project_name, sprint_name|
  @project = FactoryBot.create(:project, name: project_name, active: true)
  @sprint  = FactoryBot.create(:active_sprint, project: @project, name: sprint_name)
end

Given("the sprint has a ticket estimated {int} hours that actually took {string}") do |estimate, actual|
  FactoryBot.create(:ticket, project: @project, sprint: @sprint, status: :done,
                    dev_estimate_hours: estimate, actual_hours: actual)
end

# ── Actions ─────────────────────────────────────────────────────────────────--

When("I run the AI readiness check on that ticket") do
  visit ticket_path(@ticket)
  click_button "✅ Check readiness"
end

# The code/test review forms live inside a collapsed <details>, which Capybara's
# rack_test driver treats as hidden — interact with visible: false.
When("I submit a code review for that ticket in {string}") do |language|
  visit ticket_path(@ticket)
  find("select[name='language'] option[value='#{language}']", visible: false).select_option
  find("textarea[name='diff']", visible: false).set("func main() { fmt.Println(\"hi\") }")
  click_button "Review code", visible: false
end

When("I submit a cucumber test review for that ticket") do
  visit ticket_path(@ticket)
  find("textarea[name='feature']", visible: false).set("Feature: Login\n  Scenario: ok\n    Given a user")
  click_button "Review tests", visible: false
end

When("I ask the AI to suggest a solution for that ticket") do
  visit ticket_path(@ticket)
  click_button "💡 Suggest solution"
end

When("I run AI estimation analysis on that sprint") do
  visit sprint_path(@sprint)
  click_button "📊 AI Estimation"
end

When("I view that sprint") do
  visit sprint_path(@sprint)
end

When("I load the AI sprint analysis directly") do
  visit tools_ai_sprint_analysis_path(sprint_id: @sprint.id)
end

When("I visit the AI reports page") do
  visit tools_ai_path
end

# ── Assertions ────────────────────────────────────────────────────────────────

Then("I should see the AI review result") do
  expect(page).to have_css(".markdown-body")
end

Then("the ticket should be reassigned to its owner") do
  expect(@ticket.reload.assignee_id).to eq(@owner.id)
end

Then("I should see the live AI sprint analysis frame") do
  expect(page).to have_css("turbo-frame#ai_sprint_analysis")
end

Then("the AI review should be marked failed") do
  expect(AiReview.last).to be_status_failed
end

Then("an AI review of kind {string} should exist") do |kind|
  expect(AiReview.where(kind: kind)).to exist
end
