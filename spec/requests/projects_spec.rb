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

      it "exposes a quick status-change action per ticket" do
        get project_path(project)
        expect(response.body).to include(update_status_ticket_path(open_ticket, status: "done"))
        expect(response.body).to include(move_to_sprint_ticket_path(open_ticket, target: "backlog"))
      end
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

  # ── Sprints list on the project page ──────────────────────────────────────
  describe "project sprints list" do
    it "lists the project's sprints with estimated and actual totals" do
      sprint = create(:sprint, project: project, name: "Sprint Alpha")
      create(:ticket, project: project, sprint: sprint, dev_estimate_hours: 8, actual_hours: "6h")
      get project_path(project)
      expect(response.body).to include('id="sprints"')
      expect(response.body).to include("Sprint Alpha")
      expect(response.body).to include("Estimated")
      expect(response.body).to include("Actual")
    end

    it "offers a 'Set as active' button for non-current sprints" do
      planning = create(:sprint, project: project, name: "Sprint Planning", status: :planning)
      get project_path(project)
      expect(response.body).to include("Set as active")
      expect(response.body).to include(activate_sprint_path(planning))
    end

    it "shows ★ Active instead of the button for the current sprint" do
      create(:sprint, project: project, name: "Sprint Live", status: :active)
      get project_path(project)
      expect(response.body).to include("★ Active")
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
