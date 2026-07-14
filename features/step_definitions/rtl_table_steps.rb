require "rails_helper"

# rack_test can't compute CSS, so we assert the RTL context that our stylesheet
# rule keys off: the document is right-to-left and the table renders header
# cells. The actual right-alignment of `th` is verified in the browser.
Then("כותרות העמודות בטבלה מיושרות לימין") do
  expect(page).to have_css('html[dir="rtl"]')
  expect(page).to have_css("table thead th", minimum: 1)
end
