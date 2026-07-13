require "rails_helper"

Then("פריסת מסך היום אמורה להיערם לעמודה אחת במסכים קטנים") do
  # The body columns carry col-12 + col-xxl-* so they stack on small screens
  # (laptops) and only sit side-by-side on very wide (xxl) displays.
  expect(page).to have_css(".col-12.col-xxl-7")
end
