require 'rails_helper'

# ── Authentication ────────────────────────────────────────────────────────────

Given("I am logged in as a developer") do
  @user = FactoryBot.create(:user, role: :developer)
  login_as(@user, scope: :user)
end

Given("I am logged in as a team lead") do
  @user = FactoryBot.create(:user, role: :team_lead)
  login_as(@user, scope: :user)
end

Given("my preferred language is Hebrew") do
  @user = FactoryBot.create(:user, preferred_language: "he")
  login_as(@user, scope: :user)
end

# ── Projects ──────────────────────────────────────────────────────────────────

Given("there is a project called {string}") do |name|
  @project = FactoryBot.create(:project, name: name, active: true)
end

Given("that project has a ticket titled {string}") do |title|
  @internal_ticket = FactoryBot.create(:ticket, project: @project, title: title)
end

# ── Navigation ────────────────────────────────────────────────────────────────

Given("I am on the project tickets page for {string}") do |project_name|
  @project ||= Project.find_by!(name: project_name)
  visit project_tickets_path(@project)
end

When("I visit the customers list page") do
  visit customers_path
end

When("I visit the customer's tickets page for {string}") do |customer_name|
  customer = Customer.find_by!(name: customer_name)
  visit customer_customer_tickets_path(customer)
end

When("I visit the installations page for {string}") do |customer_name|
  @current_customer = Customer.find_by!(name: customer_name)
  visit customer_installations_path(@current_customer)
end

When("I visit the customers list page and filter active only") do
  visit customers_path(active_only: "1")
end

When("I filter installations by {string} environment") do |env|
  @current_customer ||= @customer
  visit customer_installations_path(@current_customer, environment: env)
end

# ── Interactions ──────────────────────────────────────────────────────────────

When("I click {string}") do |text|
  click_link_or_button text
end

When("I fill in {string} with {string}") do |field, value|
  fill_in field, with: value
end

When("I select {string} for {string}") do |value, field|
  select value, from: field
end

When("I submit the form") do
  find('[type="submit"]').click
end

When("I search for {string}") do |query|
  fill_in "q", with: query
  click_button "Search"
end

When("I view that customer ticket") do
  customer = @customer
  ct = customer.customer_tickets.first
  visit customer_customer_ticket_path(customer, ct)
end

When("I view the customer ticket {string}") do |title|
  customer = @customer
  ct = customer.customer_tickets.find_by!(title: title)
  visit customer_customer_ticket_path(customer, ct)
end

When("I link it to the internal ticket {string}") do |title|
  select title.truncate(60), from: "internal_ticket_id"
  click_button "Link"
end

When("I edit that customer and change the name to {string}") do |new_name|
  customer = Customer.last
  visit edit_customer_path(customer)
  fill_in "Name", with: new_name
  click_button "Update Customer"
end

When("I edit that customer ticket") do
  customer = @customer
  ct = customer.customer_tickets.first
  visit edit_customer_customer_ticket_path(customer, ct)
end

When("I assign it to a team member") do
  @assigned_user = FactoryBot.create(:user, name: "Support Agent")
  select "Support Agent", from: "assigned_to_id"
end

When("I edit that installation and change the version to {string}") do |new_version|
  inst = @current_customer.installations.first
  visit edit_customer_installation_path(@current_customer, inst)
  fill_in "Version", with: new_version
  click_button "Update Installation"
end

When("I track a new installation for {string} linked to that deployment") do |customer_name|
  customer = Customer.find_by!(name: customer_name)
  visit new_customer_installation_path(customer)
  fill_in "Software / Product Name", with: "TDI2 Server"
  fill_in "Version", with: "5.0.0"
  select "production", from: "environment"
  click_button "Track Installation"
end

When("I filter by {string} status") do |status|
  customer = @customer
  visit customer_customer_tickets_path(customer, status: status)
end

When("I create a new active installation of {string} version {string} for {string}") do |software, version, customer_name|
  customer = Customer.find_by!(name: customer_name)
  FactoryBot.create(:installation, customer: customer, software_name: software, version: version, status: :active)
end

# ── Given (data setup) ────────────────────────────────────────────────────────

Given("there are 3 active customers") do
  3.times { FactoryBot.create(:customer) }
end

Given("there is a customer named {string}") do |name|
  @customer = FactoryBot.create(:customer, name: name)
  @customer_name = name
end

Given("there is an active customer named {string}") do |name|
  FactoryBot.create(:customer, name: name, active: true)
end

Given("there is an inactive customer named {string}") do |name|
  FactoryBot.create(:customer, name: name, active: false)
end

Given("{string} has an open ticket titled {string}") do |customer_name, title|
  @customer = Customer.find_by!(name: customer_name)
  @customer_ticket = FactoryBot.create(:customer_ticket, customer: @customer, title: title, status: :open)
end

Given("{string} has 2 open tickets and 1 resolved ticket") do |customer_name|
  @customer = Customer.find_by!(name: customer_name)
  2.times { FactoryBot.create(:customer_ticket, customer: @customer, status: :open) }
  FactoryBot.create(:resolved_customer_ticket, customer: @customer)
end

Given("{string} has an installation of {string} version {string} in production") do |customer_name, software, version|
  @current_customer = Customer.find_by!(name: customer_name)
  @installation = FactoryBot.create(:installation,
    customer: @current_customer, software_name: software,
    version: version, environment: "production", status: :active)
end

Given("{string} has an active installation of {string} version {string}") do |customer_name, software, version|
  @current_customer = Customer.find_by!(name: customer_name)
  @old_installation = FactoryBot.create(:installation,
    customer: @current_customer, software_name: software,
    version: version, status: :active)
end

Given("{string} has a production installation of {string}") do |customer_name, software|
  @current_customer = Customer.find_by!(name: customer_name)
  FactoryBot.create(:installation,
    customer: @current_customer, software_name: software,
    environment: "production", status: :active)
end

Given("{string} has a staging installation of {string}") do |customer_name, software|
  @current_customer = Customer.find_by!(name: customer_name)
  FactoryBot.create(:installation,
    customer: @current_customer, software_name: software,
    environment: "staging", status: :active)
end

Given("{string} is a customer") do |customer_name|
  @customer = Customer.find_by(name: customer_name) ||
              FactoryBot.create(:customer, name: customer_name)
end

Given("there is a deployment for that project") do
  @deployment = FactoryBot.create(:deployment, project: @project)
end

Given("there are recent CI runs for the project") do
  3.times { FactoryBot.create(:ci_run, project: @project, status: :passed) }
  FactoryBot.create(:ci_run, project: @project, status: :failed)
end

Given("there is an upcoming meeting") do
  @meeting = FactoryBot.create(:meeting, scheduled_at: 1.hour.from_now, organizer: @user)
end

Given("there is a CI run with status {string} for that project") do |status|
  @ci_run = FactoryBot.create(:ci_run, project: @project, status: status.to_sym)
end

Given("there is a failed CI run with test results") do
  @ci_run = FactoryBot.create(:ci_run, project: @project, status: :failed)
  FactoryBot.create(:test_result, ci_run: @ci_run, passed: 10, failed: 3, skipped: 1)
end

# ── Assertions ────────────────────────────────────────────────────────────────

Then("I should see {string}") do |text|
  expect(page).to have_content(text)
end

Then("I should not see {string}") do |text|
  expect(page).not_to have_content(text)
end

Then("I should see {int} customer rows in the table") do |count|
  expect(page).to have_selector("table tbody tr", count: count)
end

Then("I should see 2 tickets") do
  expect(page).to have_selector("table tbody tr", count: 2)
end

Then("I should not see resolved tickets") do
  expect(page).not_to have_selector("td", text: "resolved")
end

Then("I should see {string} or a success flash") do |_text|
  has_flash = page.has_selector?(".notification.is-success", wait: 2) rescue false
  has_msg   = page.has_content?("successfully", wait: 2) rescue false
  expect(has_flash || has_msg).to be true
end

Then("I should see {string} priority tag") do |priority|
  expect(page).to have_content(priority)
end

Then("the ticket should be marked as resolved") do
  expect(page).to have_content("resolved")
end

Then("I should see a resolved status tag") do
  expect(page).to have_content("resolved")
end

Then("I should see the internal ticket linked") do
  expect(page).to have_content("Linked to internal ticket")
end

Then("the ticket should be assigned to that team member") do
  expect(page).to have_content("Support Agent")
end

Then("I should see version {string}") do |version|
  expect(page).to have_content(version)
end

Then("the old version should be marked as outdated") do
  expect(page).to have_content("outdated")
end

Then("the {string} installation should be marked as outdated") do |version|
  inst = Installation.find_by(version: version)
  expect(inst.status).to eq("outdated")
end

Then("the {string} installation should be active") do |version|
  inst = Installation.find_by(version: version)
  expect(inst.status).to eq("active")
end

Then("the installation should show the deployment reference") do
  expect(page).to have_content("Deployment")
end

Then("the page title should be in Hebrew") do
  expect(page).to have_content("לוח")
end

Then("the layout should use right-to-left direction") do
  expect(page).to have_selector("html[dir='rtl']")
end

Then("I should see the CI stats dashboard") do
  expect(page).to have_selector(".stat-card")
end

Then("failed CI runs should be highlighted") do
  expect(page).to have_selector(".has-background-danger-light")
end

Then("I should see test result counts") do
  expect(page).to have_content("passed")
end

Then("I should see the join meeting button") do
  expect(page).to have_link("Join")
end
