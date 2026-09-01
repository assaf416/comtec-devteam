require "rails_helper"

Then("אני אמור לראות תיבת כתיבה עם מסגרת נראית") do
  expect(page).to have_css(".chat-compose-box textarea")
end
