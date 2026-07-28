require "rails_helper"

Then("פריסת מסך היום אמורה להיות עמודה אחת בכל רוחב מסך") do
  # The body columns carry plain col-12 (no col-xxl-* split) so they always
  # stack full-width, regardless of screen size — a col-xxl-7/col-xxl split
  # would break this on common 13" laptop resolutions.
  expect(page).to have_css(".col-12")
  expect(page).not_to have_css("[class*='col-xxl']")
end
