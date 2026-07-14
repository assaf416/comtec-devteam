require "rails_helper"

Given("אני מחובר כמנהל") do
  @user = FactoryBot.create(:user, role: :admin)
  login_as(@user, scope: :user)
end

Given("קיים משתמש בשם {string}") do |name|
  @target_user = FactoryBot.create(:user, name: name)
end

Given("קיים משתמש חסום עם דוא\"ל {string} וסיסמה {string}") do |email, password|
  FactoryBot.create(:user, email: email, password: password,
                           password_confirmation: password, blocked: true)
end

When("אני מבקר בעמוד ניהול המשתמשים") do
  visit admin_users_path
end

When("אני מנסה לגשת לעמוד ניהול המשתמשים") do
  visit admin_users_path
end

When("אני חוסם את המשתמש {string}") do |name|
  user = User.find_by!(name: name)
  within("#user-row-#{user.id}") { click_button "Block" }
end

When("אני מנסה להתחבר עם {string} ו-{string}") do |email, password|
  visit new_user_session_path
  fill_in "user[email]",    with: email
  fill_in "user[password]", with: password
  click_button "Sign in"
end

Then("המשתמש {string} אמור להיות חסום") do |name|
  expect(User.find_by!(name: name).blocked?).to be(true)
end

Then("אני לא אמור להיות מחובר") do
  expect(page).to have_current_path(new_user_session_path)
end

Then("לא אמורה להיות מוצגת לי טבלת המשתמשים") do
  expect(page).to have_no_css("#users-table")
end
