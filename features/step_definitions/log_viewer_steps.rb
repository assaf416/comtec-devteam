# Steps for the Log Viewer feature. LogQueryService is stubbed in
# features/support/log_viewer_support.rb, so these run without a Loki server.

Given("the log store has no entries") do
  LogQueryService.test_entries = []
end

Given("the log store is unreachable") do
  LogQueryService.test_entries   = []
  LogQueryService.test_available = false
end

When("I visit the log viewer") do
  visit log_viewer_path
end

When("I view the logs filtered by level {string}") do |level|
  visit log_viewer_path(level: level)
end

When("I open the live log tail") do
  visit log_viewer_tail_path
end

Then("I should see the log filters") do
  expect(page).to have_css("select[name='service']")
  expect(page).to have_css("select[name='level']")
end

Then("error lines should be highlighted") do
  expect(page).to have_css(".log-line.log-error")
end

Then("exception lines should be highlighted") do
  expect(page).to have_css(".log-line.log-exception")
end

Then("the error count should be shown") do
  expect(page).to have_content("errors")
end
