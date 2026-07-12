require 'rails_helper'

RSpec.describe "PullRequests", type: :request do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }
  let(:ticket)  { create(:ticket, project: project) }

  before { sign_in user }

  describe "GET /pull_requests/:id" do
    let(:pr) do
      create(:pull_request, project: project, ticket: ticket, pr_number: 42, title: "Add login",
             coverage_percent: 87.5,
             files_data: [
               { "path" => "app/models/session.rb", "language" => "ruby",
                 "content" => "class Session; end", "additions" => 10, "deletions" => 2,
                 "url" => "http://gitea.local/x/src/branch/main/app/models/session.rb" },
               { "path" => "features/login.feature", "language" => "gherkin",
                 "content" => "Feature: Login\n  Scenario: ok\n    Given a\n    Then b",
                 "additions" => 8, "deletions" => 0 }
             ],
             tests_data: [
               { "name" => "logs in", "file" => "features/login.feature", "suite" => "Cucumber",
                 "status" => "passed", "time_ms" => 120 },
               { "name" => "rejects bad pw", "file" => "spec/session_spec.rb", "suite" => "Unit",
                 "status" => "failed", "time_ms" => 45 }
             ])
    end

    it "renders the file navigator with code and the tests + coverage card" do
      get pull_request_path(pr)
      expect(response).to have_http_status(:success)
      # file navigator
      expect(response.body).to include('data-controller="pr-files"')
      expect(response.body).to include("app/models/session.rb")
      expect(response.body).to include("class Session; end")
      # .feature file links to the Gherkin editor scoped to this PR
      expect(response.body).to include("cucumber_tests/edit?path=features%2Flogin.feature")
      expect(response.body).to include("pull_request_id=#{pr.id}")
      # tests + coverage
      expect(response.body).to include("Tests (2)")
      expect(response.body).to include("logs in")
      expect(response.body).to include("Coverage 87.5%")
    end
  end
end
