# Steps for the Log Viewer feature. LogQueryService is stubbed in
# features/support/log_viewer_support.rb, so these run without a Loki server.

Given("מאגר הלוגים ריק מרשומות") do
  LogQueryService.test_entries = []
end

Given("מאגר הלוגים אינו נגיש") do
  LogQueryService.test_entries   = []
  LogQueryService.test_available = false
end

When("אני מבקר במציג הלוגים") do
  visit log_viewer_path
end

When("אני צופה בלוגים מסוננים לפי רמה {string}") do |level|
  visit log_viewer_path(level: level)
end

When("אני פותח את מעקב הלוגים החי") do
  visit log_viewer_tail_path
end

Then("אני אמור לראות את מסנני הלוגים") do
  expect(page).to have_css("select[name='service']")
  expect(page).to have_css("select[name='level']")
end

Then("שורות שגיאה אמורות להיות מודגשות") do
  expect(page).to have_css(".log-line.log-error")
end

Then("שורות חריגה אמורות להיות מודגשות") do
  expect(page).to have_css(".log-line.log-exception")
end

Then("ספירת השגיאות אמורה להיות מוצגת") do
  expect(page).to have_content("errors")
end
