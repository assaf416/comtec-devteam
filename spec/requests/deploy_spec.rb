require 'rails_helper'

RSpec.describe "Deploy console", type: :request do
  let(:user)    { create(:user) }
  let(:project) { create(:project, name: "Print Server") }

  before { sign_in user }

  def heartbeat!(ip: "10.0.10.21", name: "prod-web-01")
    ServerHeartbeat.create!(ip_address: ip, server_name: name, server_os: "Ubuntu 22.04",
                            cpu: 30, mem: 40, disk: 50, error_count: 0, recorded_at: Time.current)
  end

  describe "GET /deploy" do
    it "renders the console with servers, the deploy form and recent deployments" do
      heartbeat!
      create(:ci_run, project: project, status: :passed, build_number: "1001",
             commit_sha: "abc1234def", branch_name: "main")
      create(:deployment, project: project, version: "1001", environment: "staging",
             status: :succeeded, server_name: "prod-web-01")

      get deploy_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("🚀 Deploy")
      expect(response.body).to include("New deployment")
      expect(response.body).to include("prod-web-01")          # server
      expect(response.body).to include("Recent deployments")
      expect(response.body).to include("Demo mode")            # no backend configured in test
      # the dependent-select carries this project's passing CI build as a tag
      expect(response.body).to include("deploy-form-tags-value")
      expect(response.body).to include("1001")
    end
  end

  describe "POST /deploy" do
    it "records a deployment for the chosen image tag + server (queued in demo mode)" do
      hb = heartbeat!

      expect {
        post deploy_path, params: { project_id: project.id, image_tag: "1001",
                                    environment: "staging", server_ip: hb.ip_address }
      }.to change(Deployment, :count).by(1)

      dep = Deployment.order(:created_at).last
      expect(dep.version).to eq("1001")
      expect(dep.environment).to eq("staging")
      expect(dep.ip_address).to eq(hb.ip_address)
      expect(dep.deployed_by).to eq(user)
      expect(dep.status).to eq("pending") # backend not configured → queued
      expect(response).to redirect_to(deploy_path)
    end

    it "rejects a deploy with no image tag" do
      hb = heartbeat!
      post deploy_path, params: { project_id: project.id, image_tag: "", environment: "staging", server_ip: hb.ip_address }
      expect(response).to redirect_to(deploy_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe DeployService do
    it "falls back to passing CI runs for deployable tags" do
      create(:ci_run, project: project, status: :passed, build_number: "777", commit_sha: "deadbeef", branch_name: "main")
      create(:ci_run, project: project, status: :failed, build_number: "778")
      tags = DeployService.new.deployable_tags(project)
      expect(tags.map(&:tag)).to include("777")
      expect(tags.map(&:tag)).not_to include("778")
    end
  end
end
