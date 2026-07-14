require "rails_helper"

Given("קיים מסמך בשם {string} בפרויקט {string}") do |title, project_name|
  project = Project.find_by!(name: project_name)
  @document = FactoryBot.create(:document,
                                title:   title,
                                content: "תוכן לדוגמה",
                                project: project,
                                author:  @user)
end

When("אני מבקר בעמוד המסמכים של הפרויקט {string}") do |project_name|
  project = Project.find_by!(name: project_name)
  visit project_documents_path(project)
end

Then("הקישור למסמך {string} אמור להיפתח בכרטיסייה חדשה") do |title|
  doc  = Document.find_by!(title: title)
  link = find("a[href='#{document_path(doc)}']", match: :first)
  expect(link[:target]).to eq("_blank")
end
