require 'rails_helper'

# Smoke tests for the main pages — replaces the auto-generated scaffold stubs
# that asserted success on non-existent routes. These sign in and hit the real
# routes to catch boot/render regressions across the app.
RSpec.describe "Page smoke tests", type: :request do
  let(:user) { create(:user) }

  describe "authenticated top-level pages" do
    before { sign_in user }

    {
      "dashboard"        => "/dashboard",
      "today"            => "/today",
      "calendar"         => "/calendar",
      "all tickets"      => "/tickets",
      "my tickets"       => "/tickets/mine",
      "backlog tickets"  => "/tickets/backlog",
      "current sprint"   => "/tickets/current_sprint",
      "late tickets"     => "/tickets/late",
      "all documents"    => "/documents",
      "projects"         => "/projects",
      "notifications"    => "/notifications",
      # NOTE: the /ci dashboard pages are intentionally omitted — their
      # controller (app/controllers/ci_dashboard_controller.rb) is not yet
      # committed to the repo, so those routes 404 in a clean checkout.
      "report: ci"          => "/reports/ci_summary",
      "report: deployments" => "/reports/deployment_summary",
      "report: coverage"    => "/reports/test_coverage",
      "report: velocity"    => "/reports/sprint_velocity",
      "report: estimation"  => "/reports/estimation_accuracy"
    }.each do |label, path|
      it "GET #{label} (#{path}) succeeds" do
        get path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "resource show pages" do
    let(:project) { create(:project) }

    before { sign_in user }

    it "shows a meeting" do
      sprint  = create(:sprint, project: project)
      meeting = create(:meeting, project: project, sprint: sprint, scheduled_at: 1.day.from_now)
      get meeting_path(meeting)
      expect(response).to have_http_status(:success)
    end

    it "shows a document" do
      document = create(:document, project: project)
      get document_path(document)
      expect(response).to have_http_status(:success)
    end

    it "shows a deployment" do
      deployment = create(:deployment, project: project)
      get deployment_path(deployment)
      expect(response).to have_http_status(:success)
    end

    it "shows a CI run" do
      ci_run = create(:ci_run, project: project)
      get ci_run_path(ci_run)
      expect(response).to have_http_status(:success)
    end
  end

  describe "admin pages" do
    let(:admin) { create(:user, role: :admin) }

    before { sign_in admin }

    %w[/admin/users /admin/client_accounts /admin/settings].each do |path|
      it "GET #{path} succeeds for an admin" do
        get path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "webhooks (unauthenticated, secret-verified)" do
    it "rejects a Gitea webhook without a valid signature" do
      post "/webhooks/gitea", params: "{}", headers: { "CONTENT_TYPE" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects a Jenkins webhook without a valid token" do
      post "/webhooks/jenkins", params: "{}", headers: { "CONTENT_TYPE" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "unauthenticated access" do
    it "redirects protected pages to sign-in" do
      get "/dashboard"
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
