require 'rails_helper'

RSpec.describe PullRequest, type: :model do
  let(:project) { create(:project) }
  let(:ticket)  { create(:ticket, project: project) }

  describe "#pr_files" do
    it "returns the rich files_data when present" do
      pr = create(:pull_request, project: project, ticket: ticket, pr_number: 1,
                  files_data: [{ "path" => "app/foo.rb", "language" => "ruby",
                                 "content" => "puts 1", "additions" => 3, "deletions" => 1 }])
      expect(pr.pr_files.first["path"]).to eq("app/foo.rb")
      expect(pr.pr_files.first["content"]).to eq("puts 1")
    end

    it "falls back to changed filenames with a derived language" do
      pr = create(:pull_request, project: project, ticket: ticket, pr_number: 2,
                  files_changed: ["features/login.feature"], files_data: nil)
      f = pr.pr_files.first
      expect(f["path"]).to eq("features/login.feature")
      expect(f["language"]).to eq("gherkin")
    end
  end

  describe "#feature_files" do
    it "selects only .feature files" do
      pr = create(:pull_request, project: project, ticket: ticket, pr_number: 3,
                  files_data: [{ "path" => "app/a.rb" }, { "path" => "features/b.feature" }])
      expect(pr.feature_files.map { |f| f["path"] }).to eq(["features/b.feature"])
    end
  end

  describe "#test_summary" do
    it "totals statuses from tests_data" do
      pr = create(:pull_request, project: project, ticket: ticket, pr_number: 4,
                  tests_data: [
                    { "name" => "a", "status" => "passed" },
                    { "name" => "b", "status" => "failed" },
                    { "name" => "c", "status" => "skipped" },
                    { "name" => "d", "status" => "passed" }
                  ])
      expect(pr.test_summary).to include("total" => 4, "passed" => 2, "failed" => 1, "skipped" => 1)
    end
  end

  describe ".language_for" do
    it "maps known extensions and defaults to text" do
      expect(PullRequest.language_for("x.rb")).to eq("ruby")
      expect(PullRequest.language_for("x.feature")).to eq("gherkin")
      expect(PullRequest.language_for("x.unknownext")).to eq("text")
    end
  end
end
