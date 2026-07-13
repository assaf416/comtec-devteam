require "rails_helper"

Then("תבנית הבדיקה בעורך אמורה להיות בעברית") do
  content = find("textarea[name='content']").value.to_s
  expect(content).to include("# language: he")
  expect(content).to include("תכונה")
  expect(content).to include("תרחיש")
end
