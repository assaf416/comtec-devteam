require 'rails_helper'

RSpec.describe "DevOps screens", type: :request do
  let(:user)    { create(:user, name: "Dev One") }
  let(:project) { create(:project, name: "Print Server") }
  let(:ticket)  { create(:ticket, project: project) }

  before { sign_in user }

  def heartbeat!(ip: "10.0.10.21", name: "prod-web-01")
    ServerHeartbeat.create!(ip_address: ip, server_name: name, server_os: "Ubuntu 22.04",
                            cpu: 30, mem: 40, disk: 50, error_count: 0, recorded_at: Time.current)
  end

  # ── Today: active sprints + review queue ────────────────────────────────────
  describe "GET /today" do
    it "shows an active-sprints table and the review queue" do
      create(:sprint, project: project, status: :active, name: "Sprint Live", start_date: Date.today, end_date: 7.days.from_now)
      create(:pull_request, project: project, ticket: ticket, pr_number: 4, title: "Queued PR", status: :review)
      get today_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Active sprints")
      expect(response.body).to include("Sprint Live")
      expect(response.body).to include("Review queue")
      expect(response.body).to include("Queued PR")
    end
  end

  # ── PR merge cockpit ────────────────────────────────────────────────────────
  describe "PR merge cockpit" do
    let(:pr) do
      create(:pull_request, project: project, ticket: ticket, pr_number: 3, title: "Odd PR", status: :review,
             coverage_percent: 90, tests_data: [{ "name" => "t", "status" => "passed" }],
             files_data: [{ "path" => "app/x.rb", "language" => "ruby", "content" => "puts 1\nputs 2\n" }])
    end

    it "renders pre-merge checks and a synthetic conflict for an odd PR" do
      get cockpit_pull_request_path(pr)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Pre-merge checks")
      expect(response.body).to include("Use incoming")
      expect(response.body).to include("app/x.rb")
    end

    it "merges the PR" do
      post merge_pull_request_path(pr)
      expect(pr.reload.status).to eq("merged")
      expect(pr.merged_at).to be_present
      expect(response).to redirect_to(cockpit_pull_request_path(pr))
    end
  end

  # ── Server Docker console ───────────────────────────────────────────────────
  describe "Server Docker console" do
    it "lists containers and shows Dockerfile/compose editors (demo mode)" do
      hb = heartbeat!
      get server_console_path(ip: hb.ip_address)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Docker console")
      expect(response.body).to include("Containers")
      expect(response.body).to include("postgres")          # demo container
      expect(response.body).to include("docker-compose.yml")
    end

    it "accepts a container action (queued in demo mode)" do
      hb = heartbeat!
      post server_docker_path(ip: hb.ip_address, verb: "restart", container: "app")
      expect(response).to redirect_to(server_console_path(ip: hb.ip_address))
      follow_redirect!
      expect(response.body).to include("Restart")
    end
  end

  # ── Releases + rollback ─────────────────────────────────────────────────────
  describe "Releases timeline" do
    it "shows live releases per environment" do
      create(:deployment, project: project, version: "1.0.0", environment: "production", status: :succeeded, deployed_at: 5.days.ago)
      get releases_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Releases")
      expect(response.body).to include("Production")
      expect(response.body).to include("1.0.0")
    end

    it "rolls back to the previous successful release" do
      create(:deployment, project: project, version: "1.0.0", environment: "production", status: :succeeded, deployed_at: 10.days.ago)
      current = create(:deployment, project: project, version: "2.0.0", environment: "production", status: :succeeded, deployed_at: 1.day.ago)

      expect {
        post rollback_release_path(current)
      }.to change(Deployment, :count).by(1)

      expect(current.reload.status).to eq("rolled_back")
      newest = Deployment.order(:created_at).last
      expect(newest.version).to eq("1.0.0")
      expect(newest.status).to eq("in_progress")
    end
  end

  # ── Assistant terminal ──────────────────────────────────────────────────────
  describe "Assistant terminal" do
    it "renders the console" do
      get assistant_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Assistant")
      expect(response.body).to include("/help")
    end

    it "answers a slash-command deterministically (no LLM needed)" do
      post assistant_message_path, params: { message: "/report" }
      follow_redirect!
      expect(response.body).to include("Delivery snapshot")
    end

    it "/review summarizes a PR" do
      create(:pull_request, project: project, ticket: ticket, pr_number: 7, title: "Review me", status: :open,
             tests_data: [{ "name" => "t", "status" => "passed" }], coverage_percent: 88)
      post assistant_message_path, params: { message: "/review 7" }
      follow_redirect!
      expect(response.body).to include("PR #7")
    end
  end

  describe Assistant::Agent do
    it "falls back gracefully when the LLM is offline" do
      allow_any_instance_of(Ai::OllamaClient).to receive(:converse).and_raise(Ai::OllamaClient::Error, "down")
      reply = described_class.new(user: user).respond("how do I do X?", history: [])
      expect(reply).to include("Local AI is offline")
    end
  end
end
