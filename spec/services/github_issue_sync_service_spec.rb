require "rails_helper"

RSpec.describe GithubIssueSyncService do
  let(:project) { create(:project, repo_url: "https://github.com/acme/widget") }

  # A fake GithubService returning canned issues (no network).
  def fake_client(issues)
    instance_double(GithubService).tap do |c|
      allow(c).to receive(:issues).and_return(issues)
    end
  end

  let(:issues) do
    [
      { "number" => 1, "title" => "Add SSO login", "body" => "As a user…",
        "state" => "open", "html_url" => "https://github.com/acme/widget/issues/1",
        "labels" => [ { "name" => "bug" }, { "name" => "high" } ],
        "assignee" => { "login" => "dana" } },
      { "number" => 2, "title" => "Docs typo", "body" => "fix it",
        "state" => "closed", "html_url" => "https://github.com/acme/widget/issues/2",
        "labels" => [], "assignee" => nil }
    ]
  end

  it "imports GitHub issues as tickets keyed by issue number" do
    result = described_class.new(project, client: fake_client(issues)).call

    expect(result.ok?).to be true
    expect(result.imported).to eq(2)
    expect(project.tickets.count).to eq(2)

    t1 = project.tickets.find_by(github_issue_number: 1)
    expect(t1.title).to eq("Add SSO login")
    expect(t1.status).to eq("open")
    expect(t1.kind).to eq("bug_fix")       # from the "bug" label
    expect(t1.priority).to eq("high")      # from the "high" label
    expect(t1.github_url).to eq("https://github.com/acme/widget/issues/1")
  end

  it "maps a closed issue to the closed status" do
    described_class.new(project, client: fake_client(issues)).call
    expect(project.tickets.find_by(github_issue_number: 2).status).to eq("closed")
  end

  it "is idempotent — re-running updates in place, not duplicating" do
    described_class.new(project, client: fake_client(issues)).call
    updated = issues.map { |i| i.merge("title" => "#{i['title']} (edited)") }
    result  = described_class.new(project, client: fake_client(updated)).call

    expect(result.updated).to eq(2)
    expect(project.tickets.count).to eq(2)
    expect(project.tickets.find_by(github_issue_number: 1).title).to eq("Add SSO login (edited)")
  end

  it "maps assignee login to a local user by github_login" do
    dana = create(:user, name: "Dana", github_login: "dana")
    described_class.new(project, client: fake_client(issues)).call
    expect(project.tickets.find_by(github_issue_number: 1).assignee).to eq(dana)
  end

  it "errors clearly when the project has no GitHub repo_url" do
    project.update!(repo_url: "http://gitea.local/x/y")
    result = described_class.new(project, client: fake_client(issues)).call
    expect(result.ok?).to be false
    expect(result.error).to include("no GitHub repo_url")
  end

  it "with replace: removes existing local tickets before importing" do
    create(:ticket, project: project, title: "old local ticket")
    result = described_class.new(project, client: fake_client(issues), replace: true).call
    expect(result.removed).to eq(1)
    expect(project.tickets.pluck(:title)).to match_array([ "Add SSO login", "Docs typo" ])
  end
end
