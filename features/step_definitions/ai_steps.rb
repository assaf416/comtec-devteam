# Steps for the AI Agent feature. The Ollama client is stubbed in
# features/support/ai_support.rb, so these exercise the full controller →
# service → AiReview flow without any real LLM.

# ── Setup ─────────────────────────────────────────────────────────────────────

Given("מודל ה-AI המקומי זמין") do
  Ai::OllamaClient.test_available = true
end

Given("מודל ה-AI המקומי לא מקוון") do
  Ai::OllamaClient.test_available = false
end

Given("מודל ה-AI יחזיר פסיקה {string}") do |verdict|
  Ai::OllamaClient.test_response =
    "VERDICT: #{verdict}\nSCORE: 80\n\n## Notes\nStubbed response for tests."
end

Given("פרויקט AI בשם {string} עם כרטיס {string}") do |project_name, title|
  @project = FactoryBot.create(:project, name: project_name, active: true)
  @ticket  = FactoryBot.create(:ticket, project: @project, title: title)
end

Given("פרויקט AI בשם {string} עם כרטיס {string} בבעלות {string} ומשויך ל{string}") do |project_name, title, owner_name, assignee_name|
  @project  = FactoryBot.create(:project, name: project_name, active: true)
  @owner    = FactoryBot.create(:user, name: owner_name)
  @assignee = FactoryBot.create(:user, name: assignee_name)
  @ticket   = FactoryBot.create(:ticket, project: @project, title: title,
                                owner: @owner, assignee: @assignee)
end

Given("לאותו פרויקט יש כרטיס שהוערך ב-{int} שעות ובפועל לקח {string}") do |estimate, actual|
  FactoryBot.create(:ticket, project: @project, status: :done,
                    dev_estimate_hours: estimate, actual_hours: actual)
end

# ── Actions ─────────────────────────────────────────────────────────────────--

When("אני מריץ בדיקת מוכנות AI על הכרטיס הזה") do
  visit ticket_path(@ticket)
  click_button "✅ Check readiness"
end

# The code/test review forms live inside a collapsed <details>, which Capybara's
# rack_test driver treats as hidden — interact with visible: false.
When("אני שולח סקירת קוד עבור הכרטיס הזה בשפה {string}") do |language|
  visit ticket_path(@ticket)
  find("select[name='language'] option[value='#{language}']", visible: false).select_option
  find("textarea[name='diff']", visible: false).set("func main() { fmt.Println(\"hi\") }")
  click_button "Review code", visible: false
end

When("אני שולח סקירת בדיקות cucumber עבור הכרטיס הזה") do
  visit ticket_path(@ticket)
  find("textarea[name='feature']", visible: false).set("Feature: Login\n  Scenario: ok\n    Given a user")
  click_button "Review tests", visible: false
end

When("אני מבקש מה-AI להציע פתרון עבור הכרטיס הזה") do
  visit ticket_path(@ticket)
  click_button "💡 Suggest solution"
end

When("אני מריץ ניתוח אומדני AI על אותו פרויקט") do
  visit dashboard_project_path(@project)
  click_button "🤖 Run AI estimation analysis"
end

When("אני מבקר בדף דוחות ה-AI") do
  visit tools_ai_path
end

# ── Assertions ────────────────────────────────────────────────────────────────

Then("אני אמור לראות את תוצאת סקירת ה-AI") do
  expect(page).to have_css(".markdown-body")
end

Then("הכרטיס אמור להיות משויך מחדש לבעליו") do
  expect(@ticket.reload.assignee_id).to eq(@owner.id)
end

Then("סקירת ה-AI אמורה להיות מסומנת כנכשלה") do
  expect(AiReview.last).to be_status_failed
end

Then("אמורה להתקיים סקירת AI מסוג {string}") do |kind|
  expect(AiReview.where(kind: kind)).to exist
end
