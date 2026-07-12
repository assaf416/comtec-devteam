require 'rails_helper'

RSpec.describe CodeReview, type: :model do
  describe ".parse_url" do
    it "parses a standard Gitea PR URL" do
      parts = described_class.parse_url("http://gitea.local/devteam/print-server/pulls/42")
      expect(parts).to eq(repo_owner: "devteam", repo_name: "print-server", pr_number: 42)
    end

    it "accepts the singular /pull/ form" do
      parts = described_class.parse_url("https://git.example.com/acme/api/pull/7")
      expect(parts).to eq(repo_owner: "acme", repo_name: "api", pr_number: 7)
    end

    it "returns nil for a non-PR URL" do
      expect(described_class.parse_url("http://gitea.local/devteam/print-server")).to be_nil
    end

    it "returns nil for junk" do
      expect(described_class.parse_url("not a url")).to be_nil
    end
  end
end
