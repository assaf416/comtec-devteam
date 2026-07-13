require "rails_helper"
require "rack/test"

def fixture_file(name)
  Rails.root.join("spec/fixtures/files", name)
end

Given("קיים פרויקט {string}") do |name|
  @project = FactoryBot.create(:project, name: name, active: true)
end

When("אני מעלה את הקובץ {string} לפרויקט {string}") do |filename, project_name|
  project = Project.find_by!(name: project_name)
  visit new_project_attachment_path(project)
  attach_file "attachment[files][]", fixture_file(filename)
  click_button "Upload"
end

Then("אני אמור לראות {string} ברשימת קבצי הפרויקט") do |filename|
  expect(page).to have_content(filename)
end

Then("הוא אמור להיות מוצג עם אייקון סוג הקובץ PDF") do
  expect(page).to have_content("📕")
end

Given("קיים קובץ מצורף {string} עם טקסט שחולץ {string} בפרויקט {string}") do |filename, text, project_name|
  project = Project.find_by!(name: project_name)
  attachment = project.attachments.new(uploaded_by: @user, title: filename)
  attachment.file.attach(io: File.open(fixture_file(filename)), filename: filename)
  attachment.save!
  attachment.update!(extracted_text: text, extraction_status: :done)
end

Given("קיים קובץ מצורף {string} בפרויקט {string}") do |filename, project_name|
  project = Project.find_by!(name: project_name)
  @attachment = project.attachments.new(uploaded_by: @user, title: filename)
  @attachment.file.attach(io: File.open(fixture_file(filename)), filename: filename)
  @attachment.save!
end

When("אני מחפש בקבצים {string}") do |query|
  visit attachments_path(q: query)
end

Then("אני אמור לראות {string} בתוצאות") do |text|
  expect(page).to have_content(text)
end

When("אני פותח את הקובץ המצורף {string}") do |filename|
  attachment = Attachment.joins(:file_attachment).find { |a| a.filename == filename } ||
               Attachment.find_by!(title: filename)
  visit attachment_path(attachment)
end

When("אני מבקר בדף היום") do
  visit today_path
end

Then("אני אמור לראות {string} תחת קבצים שנפתחו לאחרונה") do |filename|
  within("#section-recent-files") do
    expect(page).to have_content(filename)
  end
end

Given("יש לי אסימון API") do
  @api_user  = @user || FactoryBot.create(:user, role: :developer)
  @api_token = @api_user.api_token
end

When("אני שולח בבקשת POST את הקובץ {string} ל-API הקבצים עבור פרויקט {string}") do |filename, project_name|
  project = Project.find_by!(name: project_name)
  session = Rack::Test::Session.new(Rails.application)
  session.post(
    "/api/v1/attachments",
    {
      project_id: project.id,
      file:       Rack::Test::UploadedFile.new(fixture_file(filename), "text/plain")
    },
    { "HTTP_AUTHORIZATION" => "Bearer #{@api_token}" }
  )
  @api_status = session.last_response.status
end

Then("סטטוס תגובת ה-API אמור להיות {int}") do |status|
  expect(@api_status).to eq(status)
end

Then("אמור להתקיים קובץ מצורף {string} בפרויקט {string}") do |filename, project_name|
  project = Project.find_by!(name: project_name)
  exists  = project.attachments.any? { |a| a.filename == filename }
  expect(exists).to be true
end
