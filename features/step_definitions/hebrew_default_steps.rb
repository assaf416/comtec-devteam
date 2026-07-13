require "rails_helper"

Given("נוצר משתמש חדש ללא בחירת שפה") do
  @new_user = User.create!(
    name:     "משתמש בדיקה",
    email:    "he-default-#{SecureRandom.hex(4)}@example.com",
    password: "password123"
  )
end

Then("שפת ברירת המחדל שלו היא עברית") do
  expect(@new_user.preferred_language).to eq("he")
  expect(@new_user).to be_lang_he
end
