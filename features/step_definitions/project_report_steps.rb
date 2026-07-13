require "rails_helper"

When("אני מבקר בדף הדוח של הפרויקט {string}") do |project_name|
  project = Project.find_by!(name: project_name)
  visit report_project_path(project)
end
