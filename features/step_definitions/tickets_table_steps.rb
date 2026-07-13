require "rails_helper"

Then("אני אמור לראות טבלת כרטיסים") do
  expect(page).to have_css("table tbody tr", minimum: 1)
end
