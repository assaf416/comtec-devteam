require "rails_helper"

When("נוצר כרטיס עם שעות בפועל {string} ואומדני פיתוח {int} ובדיקות {int} בפרויקט {string}") do |actual, dev_est, test_est, project_name|
  project = Project.find_by!(name: project_name)
  @ticket = Ticket.create!(
    project: project, title: "כרטיס לבדיקת זמן פיתוח",
    dev_estimate_hours: dev_est, tester_estimate_hours: test_est, actual_hours: actual
  )
end

Then("זמן הפיתוח הכולל של הכרטיס אמור להיות {float}") do |expected|
  expect(@ticket.reload.total_development_time.to_f).to eq(expected)
end

Then("זמן הבדיקות הכולל של הכרטיס אמור להיות {float}") do |expected|
  expect(@ticket.reload.total_test_time.to_f).to eq(expected)
end
