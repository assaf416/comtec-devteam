require "rails_helper"

RSpec.describe "Api::V1 client integrations", type: :request do
  let(:user) { create(:user) }
  let(:headers) do
    {
      "Authorization" => "Bearer #{user.api_token}",
      "ACCEPT" => "application/json"
    }
  end

  describe "authentication" do
    it "rejects requests without a bearer token" do
      get "/api/v1/tickets"

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to eq("error" => "Unauthorized")
    end
  end

  describe "POST /api/v1/tickets" do
    let(:project) { create(:project, repo_url: "http://gitea.local/devteam/platform") }

    it "creates a ticket for client tools" do
      expect do
        post "/api/v1/tickets",
             params: {
               ticket: {
                 project_id: project.id,
                 title: "Extension-created ticket",
                 description: "Created from VS Code",
                 status: "open",
                 priority: "high",
                 kind: "story"
               }
             },
             headers: headers,
             as: :json
      end.to change(Ticket, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["title"]).to eq("Extension-created ticket")
      expect(body.dig("owner", "id")).to eq(user.id)
    end
  end

  describe "PATCH /api/v1/tickets/:id" do
    let(:ticket) { create(:ticket, status: :open, priority: :medium) }

    it "updates an existing ticket" do
      patch "/api/v1/tickets/#{ticket.id}",
            params: { ticket: { status: "in_progress", priority: "critical" } },
            headers: headers,
            as: :json

      expect(response).to have_http_status(:ok)
      expect(ticket.reload.status).to eq("in_progress")
      expect(ticket.priority).to eq("critical")
    end

    it "persists branch_name (used by the devteam CLI `ticket open`)" do
      patch "/api/v1/tickets/#{ticket.id}",
            params: { ticket: { branch_name: "feature/t-#{ticket.id}-cli" } },
            headers: headers,
            as: :json

      expect(response).to have_http_status(:ok)
      expect(ticket.reload.branch_name).to eq("feature/t-#{ticket.id}-cli")
      expect(response.parsed_body["branch_name"]).to eq("feature/t-#{ticket.id}-cli")
    end
  end

  describe "POST /api/v1/pull_requests" do
    let(:project) { create(:project, repo_url: "http://gitea.local/devteam/platform", default_branch: "main") }
    let(:ticket) { create(:ticket, project: project, branch_name: "feature/T-77-vscode-ticket") }

    it "generates a pull request via Gitea and stores it locally" do
      gitea = instance_double(GiteaService)
      allow(GiteaService).to receive(:new).and_return(gitea)
      allow(gitea).to receive(:create_pull_request).and_return(
        {
          "number" => 42,
          "html_url" => "http://gitea.local/devteam/platform/pulls/42"
        }
      )

      expect do
        post "/api/v1/pull_requests",
             params: {
               pull_request: {
                 ticket_id: ticket.id,
                 title: "Ticket #{ticket.id} ready for review",
                 description: "Opened by the VS Code extension"
               }
             },
             headers: headers,
             as: :json
      end.to change(PullRequest, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["pr_number"]).to eq(42)
      expect(ticket.reload.pr_number).to eq(42)
      expect(ticket.pr_url).to include("/pulls/42")
    end
  end

  describe "POST /api/v1/ci_runs" do
    let(:project) { create(:project, name: "DevTeam Hub") }
    let(:ticket) { create(:ticket, project: project, branch_name: "feature/T-12-ci") }

    it "starts a test run through Jenkins" do
      jenkins = instance_double(JenkinsService)
      allow(JenkinsService).to receive(:new).and_return(jenkins)
      allow(jenkins).to receive(:trigger_build).and_return(true)

      expect do
        post "/api/v1/ci_runs",
             params: {
               ci_run: {
                 project_id: project.id,
                 ticket_id: ticket.id,
                 job_name: "devteam-hub-smoke",
                 branch_name: ticket.branch_name
               }
             },
             headers: headers,
             as: :json
      end.to change(CiRun, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("pending")
      expect(body["job_name"]).to eq("devteam-hub-smoke")
    end
  end

  describe "POST /api/v1/ci_runs/:ci_run_id/test_results" do
    let(:ci_run) { create(:ci_run, status: :running) }

    it "stores results and closes the run as passed when failures are zero" do
      expect do
        post "/api/v1/ci_runs/#{ci_run.id}/test_results",
             params: {
               test_result: {
                 suite_name: "Playwright smoke",
                 total: 12,
                 passed: 12,
                 failed: 0,
                 skipped: 0,
                 duration_ms: 18900
               }
             },
             headers: headers,
             as: :json
      end.to change(TestResult, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(ci_run.reload.status).to eq("passed")
      expect(ci_run.finished_at).to be_present
    end
  end

  describe "POST /api/v1/deployments" do
    let(:project) { create(:project) }

    it "creates a deployment command record" do
      expect do
        post "/api/v1/deployments",
             params: {
               deployment: {
                 project_id: project.id,
                 version: "2026.05.23",
                 environment: "staging",
                 status: "in_progress",
                 deploy_type: "docker",
                 machine_name: "app-01",
                 notes: "Run smoke suite after deploy",
                 env_vars: [
                   { key: "RELEASE_SHA", value: "abc123" }
                 ]
               }
             },
             headers: headers,
             as: :json
      end.to change(Deployment, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("in_progress")
      expect(body.dig("deployed_by", "id")).to eq(user.id)
      expect(body["env_vars"]).to eq([ { "key" => "RELEASE_SHA", "value" => "abc123" } ])
    end
  end

  describe "GET /api/v1/deployments/:id" do
    let(:deployment) { create(:deployment, project: create(:project), deployed_by: user, status: :succeeded) }

    it "returns deployment status details" do
      get "/api/v1/deployments/#{deployment.id}", headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq(deployment.id)
      expect(body["status"]).to eq("succeeded")
    end
  end
end
