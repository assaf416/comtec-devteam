require "rails_helper"

# Domain/model-level steps for GitHub-sourced tickets. The GitHub API is stubbed
# (no network) so these exercise the real GithubIssueSyncService → Ticket flow.

Given("there is a GitHub-backed project called {string}") do |name|
  @project = FactoryBot.create(:project, name: name, active: true,
                               repo_url: "https://github.com/acme/#{name.parameterize}")
end

Given("the project's GitHub repo has issues:") do |table|
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

When("the GitHub issue {string} is closed and retitled {string}") do |number, title|
  issue = @gh_issues.find { |i| i["number"].to_s == number }
  issue["state"] = "closed"
  issue["title"] = title
end

When("I sync the project's GitHub issues") do
  issues = @gh_issues
  fake_client = Object.new
  fake_client.define_singleton_method(:issues) { |**_opts| issues }
  GithubIssueSyncService.new(@project, client: fake_client).call
end

Then("I should see {string} on the project tickets page") do |text|
  visit project_tickets_path(@project)
  expect(page).to have_content(text)
end

Then("the ticket {string} should be a bug_fix") do |title|
  expect(@project.tickets.find_by!(title: title).kind).to eq("bug_fix")
end

When("I open the ticket {string}") do |title|
  visit ticket_path(@project.tickets.find_by!(title: title))
end

Then("I should see a link to the GitHub issue") do
  expect(page).to have_css("a[href*='/issues/']")
end

Then("there should be no {string} button") do |label|
  expect(page).not_to have_link(label)
  expect(page).not_to have_button(label)
end

Then("the project should have exactly {int} ticket") do |count|
  expect(@project.tickets.count).to eq(count)
end

Then("the ticket for issue {string} should be closed") do |number|
  expect(@project.tickets.find_by!(github_issue_number: number.to_i).status).to eq("closed")
end
