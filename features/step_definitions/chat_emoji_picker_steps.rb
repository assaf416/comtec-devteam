require "rails_helper"

Then("לוח האמוג'י אמור להיות קיים בעמוד") do
  expect(page).to have_css(".chat-emoji-picker", visible: :all)
end

Then("לוח האמוג'י אמור להכיל לפחות {int} כפתורי אמוג'י") do |count|
  expect(page).to have_css(".chat-emoji-picker .chat-emoji-option", minimum: count, visible: :all)
end

Then("לוח האמוג'י לא אמור להיות מקונן בתוך תיבת הכתיבה") do
  doc = Nokogiri::HTML(page.body)
  picker = doc.at_css(".chat-emoji-picker")
  expect(picker.ancestors(".chat-compose-box")).to be_empty
end
