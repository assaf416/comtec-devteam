require "rails_helper"

Then("אמור להיות אזור תצוגה מקדימה לקבצים מצורפים") do
  expect(page).to have_css('[data-chat-target="attachmentsPreview"]', visible: :all)
end

Then("שדה הקובץ אמור להיות מקושר לאירוע בחירת קבצים") do
  expect(page).to have_css('input[type="file"][data-action*="filesSelected"]', visible: :all)
end
