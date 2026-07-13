require 'rails_helper'

RSpec.describe "CucumberTests", type: :request do
  let(:user)    { create(:user) }
  let(:project) { create(:project, repo_url: "http://gitea.local/devteam/x") }
  let(:ticket)  { create(:ticket, project: project) }

  before { sign_in user }

  describe "GET /cucumber_tests/edit" do
    it "renders the dark Gherkin editor (starter template when the file can't be fetched)" do
      allow_any_instance_of(GiteaService).to receive(:file_content).and_return(nil)
      get edit_cucumber_test_path(ticket_id: ticket.id, path: "features/login.feature")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Cucumber Test Editor")
      expect(response.body).to include('data-controller="gherkin-editor"')
      expect(response.body).to include("# language: he") # Hebrew starter template
      expect(response.body).to include("תכונה:")
    end

    it "loads the file content from the project's Gitea repo when available" do
      allow_any_instance_of(GiteaService).to receive(:file_content)
        .and_return("Feature: Existing\n  Scenario: It works\n    Given x\n    Then y")
      get edit_cucumber_test_path(ticket_id: ticket.id, path: "features/x.feature")
      expect(response.body).to include("Feature: Existing")
    end
  end

  describe "GET /cucumber_tests/edit?pull_request_id=" do
    it "loads the feature content from the PR's stored files (no Gitea fetch needed)" do
      pr = create(:pull_request, project: project, ticket: ticket, pr_number: 9,
                  files_data: [{ "path" => "features/checkout.feature", "language" => "gherkin",
                                 "content" => "Feature: Checkout\n  Scenario: Buy\n    Given a cart\n    Then it works" }])
      get edit_cucumber_test_path(pull_request_id: pr.id, path: "features/checkout.feature")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Feature: Checkout")
      expect(response.body).to include("Back to PR ##{pr.pr_number}")
    end
  end

  describe "POST /cucumber_tests/review" do
    it "runs the AI test review on the edited content and shows the result" do
      allow_any_instance_of(Ai::OllamaClient).to receive(:chat)
        .and_return("VERDICT: needs_work\nAdd negative scenarios.")

      expect {
        post review_cucumber_test_path, params: {
          ticket_id: ticket.id, path: "features/x.feature",
          content: "Feature: X\n  Scenario: Y\n    Given a\n    Then b"
        }
      }.to change { ticket.ai_reviews.where(kind: :test_review).count }.by(1)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("AI test review")
      expect(response.body).to include("Feature: X") # editor keeps the content
    end
  end

  describe "Files Changed panel on the ticket page" do
    it "lists PR files and links .feature files to the editor" do
      create(:pull_request, project: project, ticket: ticket, pr_number: 7,
             files_changed: [ "app/x.rb", "features/login.feature" ])
      get ticket_path(ticket)
      expect(response.body).to include("Files Changed")
      expect(response.body).to include("features/login.feature")
      expect(response.body).to include("/cucumber_tests/edit")
      expect(response.body).to include("🧪 Update test")
    end
  end
end
