require "rails_helper"

# Domain/model-level steps for GitHub-sourced tickets. The GitHub API is stubbed
# (no network) so these exercise the real GithubIssueSyncService → Ticket flow.

Given("קיים פרויקט מגובה GitHub בשם {string}") do |name|
  @project = FactoryBot.create(:project, name: name, active: true,
                               repo_url: "https://github.com/acme/#{name.parameterize}")
end

Given("מאגר ה-GitHub של הפרויקט מכיל issues:") do |table|
  @gh_issues = table.hashes.map do |row|
    number = row["number"].to_i
    {
      "number"   => number,
      "title"    => row["title"],
      "body"     => row["body"].to_s,
      "state"    => row["state"].presence || "open",
      "html_url" => "#{@project.repo_url}/issues/#{number}",
      "labels"   => row["labels"].to_s.split(/\s*,\s*/).reject(&:blank?).map { |n| { "name" => n } },
      "assignee" => nil
    }
  end
end

When("issue מספר {string} ב-GitHub נסגר ושמו שונה ל{string}") do |number, title|
  issue = @gh_issues.find { |i| i["number"].to_s == number }
  issue["state"] = "closed"
  issue["title"] = title
end

When("אני מסנכרן את ה-issues של הפרויקט מ-GitHub") do
  issues = @gh_issues
  fake_client = Object.new
  fake_client.define_singleton_method(:issues) { |**_opts| issues }
  GithubIssueSyncService.new(@project, client: fake_client).call
end

Then("אני אמור לראות {string} בדף כרטיסי הפרויקט") do |text|
  visit project_tickets_path(@project)
  expect(page).to have_content(text)
end

Then("הכרטיס {string} אמור להיות מסוג bug_fix") do |title|
  expect(@project.tickets.find_by!(title: title).kind).to eq("bug_fix")
end

When("אני פותח את הכרטיס {string}") do |title|
  visit ticket_path(@project.tickets.find_by!(title: title))
end

Then("אני אמור לראות קישור ל-issue ב-GitHub") do
  expect(page).to have_css("a[href*='/issues/']")
end

Then("לא אמור להיות כפתור {string}") do |label|
  expect(page).not_to have_link(label)
  expect(page).not_to have_button(label)
end

Then("לפרויקט אמורים להיות בדיוק {int} כרטיסים") do |count|
  expect(@project.tickets.count).to eq(count)
end

Then("הכרטיס עבור issue {string} אמור להיות סגור") do |number|
  expect(@project.tickets.find_by!(github_issue_number: number.to_i).status).to eq("closed")
end
