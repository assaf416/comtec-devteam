require "rails_helper"

When("אני מבקר בעורך הבדיקות של הפרויקט {string}") do |project_name|
  project = Project.find_by!(name: project_name)
  visit edit_cucumber_test_path(project_id: project.id)
end

Given("פריסת הבדיקות ל-GitHub תצליח עם קישור {string}") do |url|
  CucumberTestDeployer.test_result =
    CucumberTestDeployer::Result.new(ok: true, pr_url: url, branch: "test/stub")
end

When("אני כותב את הנתיב {string}") do |path|
  fill_in "path", with: path
end

When("אני כותב את תוכן הבדיקה {string}") do |content|
  find("textarea[name='content']").set(content)
end
