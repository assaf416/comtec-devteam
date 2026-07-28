require "rails_helper"

When("אני מבקר בעמוד המובייל {string}") do |page_name|
  raise "Unknown mobile page #{page_name}" unless page_name == "היום שלי"

  visit mobile_today_path
end

Then("עמוד המובייל אמור להיות במצב תצוגה בהיר") do
  # Bulma 1.x auto-applies a prefers-color-scheme: dark theme unless the
  # page opts out with data-theme="light" (as the web layout already does) —
  # missing it here was the root cause of mobile lists rendering with a
  # black background.
  expect(page).to have_selector("html[data-theme='light']")
end
