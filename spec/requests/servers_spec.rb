require 'rails_helper'

RSpec.describe "Servers", type: :request do
  let(:user) { create(:user) }
  before { sign_in user }

  def beat(ip, at, **attrs)
    ServerHeartbeat.create!(ip_address: ip, recorded_at: at, **attrs)
  end

  describe "GET /servers" do
    it "lists the distinct servers with their latest status" do
      beat("10.0.0.9", 1.hour.ago, server_name: "web-09", cpu: 30, mem: 40, disk: 50)
      beat("10.0.0.9", 1.minute.ago, server_name: "web-09", cpu: 88, mem: 40, disk: 50)
      get servers_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("web-09")
      expect(response.body).to include("10.0.0.9")
    end
  end

  describe "GET /server?ip=" do
    it "shows current + historical telemetry for a server" do
      6.times { |i| beat("10.0.0.9", (i + 1).hours.ago, server_name: "web-09", cpu: 50 + i, mem: 40, disk: 60) }
      get server_path(ip: "10.0.0.9")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("web-09")
      expect(response.body).to include("History")
    end

    it "redirects unknown servers to the index" do
      get server_path(ip: "9.9.9.9")
      expect(response).to redirect_to(servers_path)
    end
  end

  describe "POST /api/v1/heartbeats" do
    let(:headers) { { "Authorization" => "Bearer #{user.api_token}", "Content-Type" => "application/json" } }

    it "ingests a heartbeat (mapping errors → error_count)" do
      expect {
        post "/api/v1/heartbeats",
             params: { ip_address: "10.0.5.5", server_name: "agent-1", cpu: 42, mem: 55, disk: 70, errors: 3 }.to_json,
             headers: headers
      }.to change(ServerHeartbeat, :count).by(1)
      expect(response).to have_http_status(:created)
      expect(ServerHeartbeat.last.error_count).to eq(3)
    end

    it "rejects without a token" do
      post "/api/v1/heartbeats", params: { ip_address: "10.0.5.5" }.to_json,
           headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
