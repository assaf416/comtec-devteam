require 'rails_helper'

RSpec.describe "Projects", type: :request do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }

  before { sign_in user }

  describe "GET /projects" do
    it "returns http success" do
      get projects_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /projects/:id" do
    it "returns http success and shows the project name" do
      get project_path(project)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(project.name)
    end

    it "renders the Tickets panel before the CI Runs panel" do
      get project_path(project)
      expect(response.body.index('id="tickets"')).to be < response.body.index("CI Runs")
    end

    describe "tickets panel filter" do
      let!(:open_ticket) { create(:ticket, project: project, status: :in_progress, dev_estimate_hours: 5) }
      let!(:done_ticket) { create(:ticket, project: project, status: :done) }
      let!(:unestimated) { create(:ticket, project: project, status: :open, dev_estimate_hours: nil) }

      it "defaults to open tickets (excludes completed)" do
        get project_path(project)
        expect(response.body).to include("T-#{open_ticket.id}")
        expect(response.body).not_to include("T-#{done_ticket.id}")
      end

      it "shows completed tickets when filtered" do
        get project_path(project, ticket_filter: "completed")
        expect(response.body).to include("T-#{done_ticket.id}")
        expect(response.body).not_to include("T-#{open_ticket.id}")
      end

      it "shows only tickets awaiting estimation when filtered" do
        get project_path(project, ticket_filter: "needs_estimation")
        expect(response.body).to include("T-#{unestimated.id}")
        expect(response.body).not_to include("T-#{open_ticket.id}")
        expect(response.body).not_to include("T-#{done_ticket.id}")
      end

      it "links each ticket through to its detail page" do
        get project_path(project)
        expect(response.body).to include(ticket_path(open_ticket))
      end
    end
  end

  describe "POST /projects/:id/sync_issues" do
    it "runs a GitHub issue sync and redirects back to the project" do
      allow_any_instance_of(GithubIssueSyncService).to receive(:call)
        .and_return(GithubIssueSyncService::Result.new(imported: 2, updated: 1, removed: 0, skipped: 0, error: nil))
      post sync_issues_project_path(project)
      expect(response).to redirect_to(project_path(project))
      expect(flash[:notice]).to include("2 new")
    end
  end

  describe "POST /projects" do
    it "creates a project and redirects" do
      expect {
        post projects_path, params: { project: { name: "Brand New Project" } }
      }.to change(Project, :count).by(1)
      expect(response).to redirect_to(project_path(Project.last))
    end

    it "re-renders on invalid params" do
      post projects_path, params: { project: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /projects/:id" do
    it "updates the project and redirects" do
      patch project_path(project), params: { project: { name: "Renamed" } }
      expect(response).to redirect_to(project_path(project))
      expect(project.reload.name).to eq("Renamed")
    end
  end

  # ── Channels now live inside a project ────────────────────────────────────
  describe "project channels" do
    it "lists the project's channels with a project-scoped new-channel link" do
      room = ChatRoom.create!(name: "proj-#{project.id}-general", project: project, room_type: :project_room)
      get project_path(project)
      expect(response.body).to include("Channels")
      expect(response.body).to include(chat_room_path(room))
      expect(response.body).to include(new_chat_room_path(project_id: project.id))
    end

    it "pre-links a new channel to the project when launched from it" do
      get new_chat_room_path(project_id: project.id)
      expect(response).to have_http_status(:success)
      expect(response.body).to match(/<option selected="selected" value="#{project.id}"/)
    end
  end

  # ── GET /projects/:id/dashboard ───────────────────────────────────────────
  describe "GET /projects/:id/dashboard" do
    before do
      create(:ticket, project: project, status: :done)
      create(:ticket, project: project, status: :blocked)
      create(:ticket, project: project, status: :open, dev_estimate_hours: nil)
    end

    it "renders the analytical dashboard with summary and insights" do
      get dashboard_project_path(project)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Dashboard")
      expect(response.body).to include("Analysis &amp; Insights")
      expect(response.body).to include("Tickets by status")
    end

    it "is linked from the project page" do
      get project_path(project)
      expect(response.body).to include(dashboard_project_path(project))
    end
  end
end
