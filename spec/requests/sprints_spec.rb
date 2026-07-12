require 'rails_helper'

RSpec.describe "Sprints", type: :request do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }
  let!(:sprint) { create(:sprint, project: project) }

  before { sign_in user }

  # ── GET /projects/:project_id/sprints ─────────────────────────────────────
  describe "GET /projects/:project_id/sprints" do
    it "returns http success" do
      get project_sprints_path(project)
      expect(response).to have_http_status(:success)
    end

    it "displays the sprint name" do
      get project_sprints_path(project)
      expect(response.body).to include(sprint.name)
    end

    it "shows active sprint banner when present" do
      active = create(:active_sprint, project: project)
      get project_sprints_path(project)
      expect(response.body).to include("Active Sprint")
      expect(response.body).to include(active.name)
    end
  end

  # ── GET /sprints/:id ──────────────────────────────────────────────────────
  describe "GET /sprints/:id" do
    it "returns http success" do
      get sprint_path(sprint)
      expect(response).to have_http_status(:success)
    end

    it "displays sprint details" do
      get sprint_path(sprint)
      expect(response.body).to include(sprint.name)
      expect(response.body).to include(sprint.start_date.strftime("%d %b %Y"))
    end

    it "shows linked tickets" do
      ticket = create(:ticket, project: project, sprint: sprint)
      get sprint_path(sprint)
      expect(response.body).to include(ticket.title)
    end

    it "shows linked meetings" do
      meeting = create(:meeting, project: project, sprint: sprint,
                        scheduled_at: 1.day.from_now, title: "Sprint Planning")
      get sprint_path(sprint)
      expect(response.body).to include("Sprint Planning")
    end

    it "shows progress percentage" do
      done_ticket = create(:ticket, project: project, sprint: sprint, status: :done)
      get sprint_path(sprint)
      expect(response.body).to match(/\d+%/)
    end

    it "shows the top tiles incl. a bug count (bugs, not stories)" do
      create(:ticket, project: project, sprint: sprint, kind: :bug_fix)
      create(:ticket, project: project, sprint: sprint, kind: :story)
      get sprint_path(sprint)
      expect(response.body).to include("Team velocity")
      expect(response.body).to include("🐞 Bugs")
    end

    it "tabs the tickets into open / completed / needs estimation" do
      open_t      = create(:ticket, project: project, sprint: sprint, title: "Open work", status: :open, story_points: 3, dev_estimate_hours: 8)
      done_t      = create(:ticket, project: project, sprint: sprint, title: "Shipped work", status: :done)
      unestimated = create(:ticket, project: project, sprint: sprint, title: "Fuzzy work", status: :open, story_points: nil, dev_estimate_hours: nil)

      get sprint_path(sprint, tab: "completed")
      expect(response.body).to include("Shipped work")
      expect(response.body).not_to include("Open work")

      get sprint_path(sprint, tab: "needs_estimation")
      expect(response.body).to include("Fuzzy work")
      expect(response.body).to include("Refine →")
    end

    it "shows sprint comments with their kind (green/red card)" do
      sprint.comments.create!(kind: :green_card, body: "Nice momentum!", author: user)
      sprint.comments.create!(kind: :red_card, body: "Scope slipped", author: user)
      get sprint_path(sprint)
      expect(response.body).to include("Sprint comments")
      expect(response.body).to include("Green card")
      expect(response.body).to include("Red card")
      # the comment form lets you choose the kind
      expect(response.body).to include('name="comment[kind]"')
    end

    it "lists documents created in this sprint" do
      project.documents.create!(title: "Sprint Plan v1", content: "# Plan", sprint: sprint, doc_type: :timeline)
      get sprint_path(sprint)
      expect(response.body).to include("Sprint documents")
      expect(response.body).to include("Sprint Plan v1")
    end
  end

  # ── Sprint comment kind ─────────────────────────────────────────────────────
  describe "POST /sprints/:sprint_id/comments with a kind" do
    it "stores the selected kind" do
      post sprint_comments_path(sprint), params: { comment: { body: "Blocker!", kind: "red_card" } }
      expect(sprint.comments.last.kind).to eq("red_card")
    end

    it "defaults to note for an invalid/blank kind" do
      post sprint_comments_path(sprint), params: { comment: { body: "fyi", kind: "bogus" } }
      expect(sprint.comments.last.kind).to eq("note")
    end
  end

  # ── GET /projects/:project_id/sprints/new ─────────────────────────────────
  describe "GET /projects/:project_id/sprints/new" do
    it "returns http success" do
      get new_project_sprint_path(project)
      expect(response).to have_http_status(:success)
    end
  end

  # ── POST /projects/:project_id/sprints ────────────────────────────────────
  describe "POST /projects/:project_id/sprints" do
    let(:valid_params) do
      { sprint: { name: "Sprint 2", start_date: Date.today,
                  end_date: Date.today + 14, status: :planning, velocity: 30 } }
    end

    context "with valid params" do
      it "creates a sprint and redirects to show" do
        expect {
          post project_sprints_path(project), params: valid_params
        }.to change(Sprint, :count).by(1)
        expect(response).to redirect_to(sprint_path(Sprint.last))
      end
    end

    context "with invalid params" do
      it "re-renders new when name is blank" do
        post project_sprints_path(project), params: { sprint: { name: "", start_date: Date.today, end_date: Date.today + 7 } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "re-renders new when end_date is before start_date" do
        post project_sprints_path(project), params: { sprint: { name: "Bad", start_date: Date.today, end_date: Date.today - 1 } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # ── GET /sprints/:id/edit ─────────────────────────────────────────────────
  describe "GET /sprints/:id/edit" do
    it "returns http success" do
      get edit_sprint_path(sprint)
      expect(response).to have_http_status(:success)
    end
  end

  # ── PATCH /sprints/:id ────────────────────────────────────────────────────
  describe "PATCH /sprints/:id" do
    it "updates and redirects to show" do
      patch sprint_path(sprint), params: { sprint: { name: "Updated Sprint", end_date: sprint.end_date } }
      expect(response).to redirect_to(sprint_path(sprint))
      expect(sprint.reload.name).to eq("Updated Sprint")
    end

    it "re-renders edit on invalid data" do
      patch sprint_path(sprint), params: { sprint: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  # ── DELETE /sprints/:id ───────────────────────────────────────────────────
  describe "DELETE /sprints/:id" do
    it "destroys the sprint and redirects to project sprints" do
      expect {
        delete sprint_path(sprint)
      }.to change(Sprint, :count).by(-1)
      expect(response).to redirect_to(project_sprints_path(project))
    end
  end

  # ── Sprint comments ───────────────────────────────────────────────────────
  describe "POST /sprints/:sprint_id/comments" do
    it "creates a comment" do
      expect {
        post sprint_comments_path(sprint), params: { comment: { body: "Great progress!" } }
      }.to change(Comment, :count).by(1)
      expect(response).to redirect_to(sprint_path(sprint))
    end

    it "rejects blank comments" do
      expect {
        post sprint_comments_path(sprint), params: { comment: { body: "" } }
      }.not_to change(Comment, :count)
    end
  end

  # ── Unauthenticated access ────────────────────────────────────────────────
  describe "when not signed in" do
    before { sign_out user }

    it "redirects to sign-in" do
      get project_sprints_path(project)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  # ── PATCH /sprints/:id/activate (set as current) ──────────────────────────
  describe "PATCH /sprints/:id/activate" do
    let!(:previous_current) { create(:active_sprint, project: project) }
    let!(:planning_sprint)  { create(:sprint, project: project, status: :planning) }

    it "makes the chosen sprint current and closes the previous one" do
      patch activate_sprint_path(planning_sprint)
      expect(planning_sprint.reload.status).to eq("active")
      expect(previous_current.reload.status).to eq("completed")
      expect(project.sprints.active.count).to eq(1)
      expect(response).to redirect_to(sprint_path(planning_sprint))
    end

    it "does not affect active sprints in other projects" do
      other = create(:active_sprint, project: create(:project))
      patch activate_sprint_path(planning_sprint)
      expect(other.reload.status).to eq("active")
    end
  end

  describe "sprint participants" do
    let!(:sprint) { create(:sprint, project: project) }
    let(:dev)     { create(:user, name: "Dana Dev") }
    let(:owner)   { create(:user, name: "Omri Owner") }

    it "is the distinct set of ticket assignees and owners" do
      create(:ticket, project: project, sprint: sprint, assignee: dev, owner: owner)
      create(:ticket, project: project, sprint: sprint, assignee: dev)
      expect(sprint.participants).to contain_exactly(dev, owner)
    end

    it "is shown on the sprint page" do
      create(:ticket, project: project, sprint: sprint, assignee: dev)
      get sprint_path(sprint)
      expect(response.body).to include("Sprint team")
      expect(response.body).to include("Dana Dev")
    end
  end

  # ── GET /sprints/:id/dashboard ────────────────────────────────────────────
  describe "GET /sprints/:id/dashboard" do
    let!(:sprint) { create(:active_sprint, project: project) }

    before do
      create(:ticket, project: project, sprint: sprint, status: :done, story_points: 3)
      create(:ticket, project: project, sprint: sprint, status: :in_progress, story_points: 5)
    end

    it "renders the analytical dashboard with summary, insights and the AI frame" do
      get dashboard_sprint_path(sprint)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Dashboard")
      expect(response.body).to include("Analysis &amp; Insights")
      expect(response.body).to include("Tickets by status")
      # Live AI analysis is embedded as a lazy turbo frame
      expect(response.body).to include('id="ai_sprint_analysis"')
      expect(response.body).to include(tools_ai_sprint_analysis_path(sprint_id: sprint.id))
    end

    it "is linked from the sprint page" do
      get sprint_path(sprint)
      expect(response.body).to include(dashboard_sprint_path(sprint))
    end
  end
end
