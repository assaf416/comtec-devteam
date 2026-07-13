require "rails_helper"

RSpec.describe "TimeLogs", type: :request do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }

  before { sign_in user }

  describe "GET /time_logs" do
    it "lists my entries and this-week totals" do
      create(:time_log, user: user, project: project, hours: 3, spent_on: Date.current, note: "Standup + coding")
      get time_logs_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Standup + coding")
      expect(response.body).to include(project.name)
    end
  end

  describe "POST /time_logs" do
    it "creates a time entry for the current user" do
      expect {
        post time_logs_path, params: { time_log: { project_id: project.id, hours: "4.0", spent_on: Date.current } }
      }.to change(user.time_logs, :count).by(1)
      expect(response).to redirect_to(time_logs_path)
    end

    it "rejects a zero-hours entry" do
      post time_logs_path, params: { time_log: { project_id: project.id, hours: "0", spent_on: Date.current } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /time_logs/:id" do
    it "removes my entry" do
      log = create(:time_log, user: user, project: project)
      expect { delete time_log_path(log) }.to change(user.time_logs, :count).by(-1)
    end
  end
end
