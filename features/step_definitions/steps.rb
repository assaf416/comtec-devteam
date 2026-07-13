require 'rails_helper'

# ── Authentication ────────────────────────────────────────────────────────────

Given("אני מחובר כמפתח") do
  @user = FactoryBot.create(:user, role: :developer)
  login_as(@user, scope: :user)
end

Given("אני מחובר כראש צוות") do
  @user = FactoryBot.create(:user, role: :team_lead)
  login_as(@user, scope: :user)
end

Given("שפת ההעדפה שלי היא עברית") do
  @user = FactoryBot.create(:user, preferred_language: "he")
  login_as(@user, scope: :user)
end

# ── Projects ──────────────────────────────────────────────────────────────────

Given("קיים פרויקט בשם {string}") do |name|
  @project = FactoryBot.create(:project, name: name, active: true)
end

Given("לפרויקט יש כרטיס בכותרת {string}") do |title|
  @internal_ticket = FactoryBot.create(:ticket, project: @project, title: title)
end

# ── Navigation ────────────────────────────────────────────────────────────────

Given("אני בדף כרטיסי הפרויקט של {string}") do |project_name|
  @project ||= Project.find_by!(name: project_name)
  visit project_tickets_path(@project)
end

When("אני מבקר בדף רשימת הלקוחות") do
  visit customers_path
end

When("אני מבקר בדף הכרטיסים של הלקוח {string}") do |customer_name|
  customer = Customer.find_by!(name: customer_name)
  visit customer_customer_tickets_path(customer)
end

When("אני מבקר בדף ההתקנות של {string}") do |customer_name|
  @current_customer = Customer.find_by!(name: customer_name)
  visit customer_installations_path(@current_customer)
end

When("אני מבקר בדף רשימת הלקוחות ומסנן פעילים בלבד") do
  visit customers_path(active_only: "1")
end

When("אני מסנן התקנות לפי סביבה {string}") do |env|
  @current_customer ||= @customer
  visit customer_installations_path(@current_customer, environment: env)
end

# ── Interactions ──────────────────────────────────────────────────────────────

When("אני לוחץ {string}") do |text|
  click_link_or_button text
end

When("אני ממלא {string} בערך {string}") do |field, value|
  fill_in field, with: value
end

When("אני בוחר {string} עבור {string}") do |value, field|
  select value, from: field
end

When("אני שולח את הטופס") do
  find('[type="submit"]').click
end

When("אני מחפש {string}") do |query|
  fill_in "q", with: query
  click_button "Search"
end

When("אני צופה בכרטיס הלקוח הזה") do
  customer = @customer
  ct = customer.customer_tickets.first
  visit customer_customer_ticket_path(customer, ct)
end

When("אני צופה בכרטיס הלקוח {string}") do |title|
  customer = @customer
  ct = customer.customer_tickets.find_by!(title: title)
  visit customer_customer_ticket_path(customer, ct)
end

When("אני מקשר אותו לכרטיס הפנימי {string}") do |title|
  select title.truncate(60), from: "internal_ticket_id"
  click_button "Link"
end

When("אני עורך את הלקוח הזה ומשנה את השם ל{string}") do |new_name|
  customer = Customer.last
  visit edit_customer_path(customer)
  fill_in "Name", with: new_name
  click_button "Update Customer"
end

When("אני עורך את כרטיס הלקוח הזה") do
  customer = @customer
  ct = customer.customer_tickets.first
  visit edit_customer_customer_ticket_path(customer, ct)
end

When("אני משייך אותו לחבר צוות") do
  @assigned_user = FactoryBot.create(:user, name: "Support Agent")
  select "Support Agent", from: "assigned_to_id"
end

When("אני עורך את ההתקנה הזו ומשנה את הגרסה ל{string}") do |new_version|
  inst = @current_customer.installations.first
  visit edit_customer_installation_path(@current_customer, inst)
  fill_in "Version", with: new_version
  click_button "Update Installation"
end

When("אני מתעד התקנה חדשה עבור {string} המקושרת לאותה פריסה") do |customer_name|
  customer = Customer.find_by!(name: customer_name)
  visit new_customer_installation_path(customer)
  fill_in "Software / Product Name", with: "TDI2 Server"
  fill_in "Version", with: "5.0.0"
  select "production", from: "environment"
  click_button "Track Installation"
end

When("אני מסנן לפי סטטוס {string}") do |status|
  customer = @customer
  visit customer_customer_tickets_path(customer, status: status)
end

When("אני יוצר התקנה פעילה חדשה של {string} גרסה {string} עבור {string}") do |software, version, customer_name|
  customer = Customer.find_by!(name: customer_name)
  FactoryBot.create(:installation, customer: customer, software_name: software, version: version, status: :active)
end

# ── Given (data setup) ────────────────────────────────────────────────────────

Given("קיימים 3 לקוחות פעילים") do
  3.times { FactoryBot.create(:customer) }
end

Given("קיים לקוח בשם {string}") do |name|
  @customer = FactoryBot.create(:customer, name: name)
  @customer_name = name
end

Given("קיים לקוח פעיל בשם {string}") do |name|
  FactoryBot.create(:customer, name: name, active: true)
end

Given("קיים לקוח לא פעיל בשם {string}") do |name|
  FactoryBot.create(:customer, name: name, active: false)
end

Given("ל{string} יש כרטיס פתוח בכותרת {string}") do |customer_name, title|
  @customer = Customer.find_by!(name: customer_name)
  @customer_ticket = FactoryBot.create(:customer_ticket, customer: @customer, title: title, status: :open)
end

Given("ל{string} יש 2 כרטיסים פתוחים וכרטיס אחד שנפתר") do |customer_name|
  @customer = Customer.find_by!(name: customer_name)
  2.times { FactoryBot.create(:customer_ticket, customer: @customer, status: :open) }
  FactoryBot.create(:resolved_customer_ticket, customer: @customer)
end

Given("ל{string} יש התקנה של {string} גרסה {string} בסביבת ייצור") do |customer_name, software, version|
  @current_customer = Customer.find_by!(name: customer_name)
  @installation = FactoryBot.create(:installation,
    customer: @current_customer, software_name: software,
    version: version, environment: "production", status: :active)
end

Given("ל{string} יש התקנה פעילה של {string} גרסה {string}") do |customer_name, software, version|
  @current_customer = Customer.find_by!(name: customer_name)
  @old_installation = FactoryBot.create(:installation,
    customer: @current_customer, software_name: software,
    version: version, status: :active)
end

Given("ל{string} יש התקנת ייצור של {string}") do |customer_name, software|
  @current_customer = Customer.find_by!(name: customer_name)
  FactoryBot.create(:installation,
    customer: @current_customer, software_name: software,
    environment: "production", status: :active)
end

Given("ל{string} יש התקנת בדיקות של {string}") do |customer_name, software|
  @current_customer = Customer.find_by!(name: customer_name)
  FactoryBot.create(:installation,
    customer: @current_customer, software_name: software,
    environment: "staging", status: :active)
end

Given("{string} הוא לקוח") do |customer_name|
  @customer = Customer.find_by(name: customer_name) ||
              FactoryBot.create(:customer, name: customer_name)
end

Given("קיימת פריסה עבור אותו פרויקט") do
  @deployment = FactoryBot.create(:deployment, project: @project)
end

Given("קיימות ריצות CI אחרונות עבור הפרויקט") do
  3.times { FactoryBot.create(:ci_run, project: @project, status: :passed) }
  FactoryBot.create(:ci_run, project: @project, status: :failed)
end

Given("קיימת פגישה קרובה") do
  @meeting = FactoryBot.create(:meeting, scheduled_at: 1.hour.from_now, organizer: @user)
end

Given("קיימת ריצת CI בסטטוס {string} עבור אותו פרויקט") do |status|
  @ci_run = FactoryBot.create(:ci_run, project: @project, status: status.to_sym)
end

Given("קיימת ריצת CI שנכשלה עם תוצאות בדיקה") do
  @ci_run = FactoryBot.create(:ci_run, project: @project, status: :failed)
  FactoryBot.create(:test_result, ci_run: @ci_run, passed: 10, failed: 3, skipped: 1)
end

# ── Assertions ────────────────────────────────────────────────────────────────

Then("אני אמור לראות {string}") do |text|
  expect(page).to have_content(text)
end

Then("אני לא אמור לראות {string}") do |text|
  expect(page).not_to have_content(text)
end

Then("אני אמור לראות {int} שורות לקוח בטבלה") do |count|
  expect(page).to have_selector("table tbody tr", count: count)
end

Then("אני אמור לראות 2 כרטיסים") do
  expect(page).to have_selector("table tbody tr", count: 2)
end

Then("אני לא אמור לראות כרטיסים שנפתרו") do
  expect(page).not_to have_selector("td", text: "resolved")
end

Then("אני אמור לראות {string} או הודעת הצלחה") do |_text|
  has_flash = page.has_selector?(".notification.is-success", wait: 2) rescue false
  has_msg   = page.has_content?("successfully", wait: 2) rescue false
  expect(has_flash || has_msg).to be true
end

Then("אני אמור לראות תגית עדיפות {string}") do |priority|
  expect(page).to have_content(priority)
end

Then("הכרטיס אמור להיות מסומן כנפתר") do
  expect(page).to have_content("resolved")
end

Then("אני אמור לראות תגית סטטוס נפתר") do
  expect(page).to have_content("resolved")
end

Then("אני אמור לראות שהכרטיס הפנימי מקושר") do
  expect(page).to have_content("Linked to internal ticket")
end

Then("הכרטיס אמור להיות משויך לאותו חבר צוות") do
  expect(page).to have_content("Support Agent")
end

Then("אני אמור לראות גרסה {string}") do |version|
  expect(page).to have_content(version)
end

Then("הגרסה הישנה אמורה להיות מסומנת כמיושנת") do
  expect(page).to have_content("outdated")
end

Then("התקנת {string} אמורה להיות מסומנת כמיושנת") do |version|
  inst = Installation.find_by(version: version)
  expect(inst.status).to eq("outdated")
end

Then("התקנת {string} אמורה להיות פעילה") do |version|
  inst = Installation.find_by(version: version)
  expect(inst.status).to eq("active")
end

Then("ההתקנה אמורה להציג את הפניית הפריסה") do
  expect(page).to have_content("Deployment")
end

Then("כותרת הדף אמורה להיות בעברית") do
  expect(page).to have_content("לוח")
end

Then("הפריסה אמורה להשתמש בכיוון מימין לשמאל") do
  expect(page).to have_selector("html[dir='rtl']")
end

Then("אני אמור לראות את לוח מחווני ה-CI") do
  expect(page).to have_selector(".stat-card")
end

Then("ריצות CI שנכשלו אמורות להיות מודגשות") do
  expect(page).to have_selector(".has-background-danger-light")
end

Then("אני אמור לראות ספירת תוצאות בדיקה") do
  expect(page).to have_content("passed")
end

Then("אני אמור לראות את כפתור ההצטרפות לפגישה") do
  expect(page).to have_link("Join")
end
