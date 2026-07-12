require 'rails_helper'

RSpec.describe "Tickets", type: :request do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }
  let!(:ticket) { create(:ticket, project: project) }

  before { sign_in user }

  # ── GET /projects/:project_id/tickets ─────────────────────────────────────
  describe "GET /projects/:project_id/tickets" do
    it "returns http success" do
      get project_tickets_path(project)
      expect(response).to have_http_status(:success)
    end

    it "displays the project name" do
      get project_tickets_path(project)
      expect(response.body).to include(project.name)
    end
  end

  # ── GET /tickets (cross-project list) ─────────────────────────────────────
  describe "GET /tickets" do
    it "renders the row actions dropdown with move options" do
      get all_tickets_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(move_to_sprint_ticket_path(ticket, target: "current"))
      expect(response.body).to include(I18n.t("tickets.move.current_sprint"))
      expect(response.body).to include(I18n.t("tickets.move.next_sprint"))
      expect(response.body).to include(I18n.t("tickets.move.backlog"))
    end

    it "shows the common-query links with the index marked active" do
      get all_tickets_path
      expect(response.body).to include(my_tickets_path)
      expect(response.body).to include(late_tickets_path)
      expect(response.body).to include(backlog_tickets_path)
      expect(response.body).to include(current_sprint_tickets_path)
      expect(response.body).to include("btn btn-primary")
    end
  end

  # ── Common-query pages share the quick-query bar ──────────────────────────
  describe "common ticket queries" do
    it "renders the quick-query bar on the My Tickets page" do
      get my_tickets_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(all_tickets_path)
      expect(response.body).to include(late_tickets_path)
    end
  end

  # ── Sidebar: Tickets moved to the main nav, panel removed ─────────────────
  describe "sidebar navigation" do
    it "links to Tickets from the main nav and drops the old Tickets panel" do
      get today_path
      expect(response.body).to include(%(nav-icon">🎫</span> #{I18n.t('nav.tickets')}))
      expect(response.body).not_to match(%r{sidebar-section-label">#{I18n.t('sidebar.tickets_label')}<})
      # Dashboard was removed from the main nav (now lives under projects/sprints)
      expect(response.body).not_to include(%(nav-icon">📊</span> #{I18n.t('nav.dashboard')}))
      # Channels were removed from the main nav (now live inside a project)
      expect(response.body).not_to include(%(sidebar-section-label">\n    #{I18n.t('sidebar.channels_label')}))
      expect(response.body).not_to match(%r{sidebar-section-label">\s*#{I18n.t('sidebar.channels_label')}})
    end
  end

  # ── GET /tickets/:id ──────────────────────────────────────────────────────
  describe "GET /tickets/:id" do
    it "returns http success" do
      get ticket_path(ticket)
      expect(response).to have_http_status(:success)
    end

    it "displays the ticket title" do
      get ticket_path(ticket)
      expect(response.body).to include(ticket.title)
    end

    it "renders a key/value Details panel with status, assignee and owner" do
      assignee = create(:user, name: "Dana Dev")
      owner    = create(:user, name: "Omri Owner")
      ticket.update!(assignee: assignee, owner: owner, status: :in_progress)
      get ticket_path(ticket)
      expect(response.body).to include("Details")
      expect(response.body).to include("Dana Dev")
      expect(response.body).to include("Omri Owner")
    end

    it "renders an Evaluation & Time panel with the estimates" do
      ticket.update!(dev_estimate_hours: 8, tester_estimate_hours: 4, actual_hours: "1d 2h")
      get ticket_path(ticket)
      expect(response.body).to include("Evaluation")
      expect(response.body).to include("1d 2h")
    end

    it "places the Comments section before the CI panel" do
      get ticket_path(ticket)
      expect(response.body.index('id="comments"')).to be < response.body.index('id="ci-runs"')
    end

    it "links to detailed test results for a CI run that has them" do
      run = create(:ci_run, project: project, ticket: ticket)
      create(:test_result, ci_run: run)
      get ticket_path(ticket)
      expect(response.body).to include(ci_run_path(run, anchor: "test-results"))
      expect(response.body).to include("View test results")
    end
  end

  # ── GET /projects/:project_id/tickets/new ─────────────────────────────────
  describe "GET /projects/:project_id/tickets/new" do
    it "returns http success" do
      get new_project_ticket_path(project)
      expect(response).to have_http_status(:success)
    end
  end

  # ── POST /projects/:project_id/tickets ────────────────────────────────────
  describe "POST /projects/:project_id/tickets" do
    context "with valid params" do
      it "creates a ticket and redirects" do
        expect {
          post project_tickets_path(project), params: {
            ticket: { title: "New ticket", status: "open", priority: "medium" }
          }
        }.to change(Ticket, :count).by(1)
        expect(response).to redirect_to(ticket_path(Ticket.last))
      end
    end

    context "with invalid params (blank title)" do
      it "re-renders the form with unprocessable_entity" do
        post project_tickets_path(project), params: {
          ticket: { title: "" }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # ── GET /tickets/:id/edit ─────────────────────────────────────────────────
  describe "GET /tickets/:id/edit" do
    it "returns http success" do
      get edit_ticket_path(ticket)
      expect(response).to have_http_status(:success)
    end

    it "shows the How to Reproduce editor under the description" do
      get edit_ticket_path(ticket)
      desc_pos = response.body.index("ticket_description")
      htr_pos  = response.body.index("ticket_how_to_reproduce_input")
      expect(htr_pos).to be_present
      expect(desc_pos).to be < htr_pos
    end

    it "defaults to the short specs form (no estimation fields)" do
      get edit_ticket_path(ticket)
      expect(response.body).to include("ticket_how_to_reproduce_input")
      expect(response.body).not_to include("ticket_dev_estimate_hours")
      # both section links are offered
      expect(response.body).to include(edit_ticket_path(ticket, section: "estimation"))
    end

    it "exposes the estimate fields on the estimation section" do
      ticket.update!(approved_at: Time.current, story_points: nil, dev_estimate_hours: nil)
      get edit_ticket_path(ticket, section: "estimation")
      expect(response.body).to include("Refinement &amp; Estimation")
      expect(response.body).to include("ticket_dev_estimate_hours")
    end

    it "shows the current estimation value on the estimation section when estimated" do
      ticket.update!(approved_at: Time.current, story_points: 8, dev_estimate_hours: 12, tester_estimate_hours: 4)
      get edit_ticket_path(ticket, section: "estimation")
      expect(response.body).to include("Current estimation:")
      expect(response.body).to include("8")
    end
  end

  # ── PATCH /tickets/:id ────────────────────────────────────────────────────
  describe "PATCH /tickets/:id" do
    context "with valid params" do
      it "updates the ticket and redirects" do
        patch ticket_path(ticket), params: {
          ticket: { title: "Updated title", status: "in_progress" }
        }
        expect(response).to redirect_to(ticket_path(ticket))
        expect(ticket.reload.title).to eq("Updated title")
        expect(ticket.reload.status).to eq("in_progress")
      end

      it "sets estimated_by to the current user when editing the estimation section" do
        patch ticket_path(ticket), params: {
          section: "estimation",
          ticket: { dev_estimate_hours: "6.0", actual_hours: "1d 2h" }
        }

        expect(response).to redirect_to(ticket_path(ticket))
        expect(ticket.reload.estimated_by_id).to eq(user.id)
      end

      it "does not stamp estimated_by when editing the specs section" do
        patch ticket_path(ticket), params: {
          section: "specs",
          ticket: { title: "Specs only edit" }
        }
        expect(ticket.reload.estimated_by_id).to be_nil
      end
    end

    context "updating estimate fields" do
      it "updates dev and QA estimates" do
        patch ticket_path(ticket), params: {
          ticket: { dev_estimate_hours: "4.5", tester_estimate_hours: "2.0" }
        }
        expect(ticket.reload.dev_estimate_hours).to eq(4.5)
        expect(ticket.reload.tester_estimate_hours).to eq(2.0)
      end
    end

    context "with invalid params" do
      it "re-renders the form" do
        patch ticket_path(ticket), params: { ticket: { title: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # ── DELETE /tickets/:id ───────────────────────────────────────────────────
  describe "DELETE /tickets/:id" do
    it "destroys the ticket and redirects to project tickets" do
      expect {
        delete ticket_path(ticket)
      }.to change(Ticket, :count).by(-1)
      expect(response).to redirect_to(project_tickets_path(project))
    end
  end

  # ── PATCH /tickets/:id/move_to_sprint ─────────────────────────────────────
  describe "PATCH /tickets/:id/move_to_sprint" do
    context "target: current" do
      let!(:current_sprint) { create(:active_sprint, project: project) }
      let!(:ticket) { create(:ticket, project: project, status: :backlog) }

      it "assigns the current sprint and promotes it out of the backlog" do
        patch move_to_sprint_ticket_path(ticket, target: "current")
        expect(ticket.reload.sprint).to eq(current_sprint)
        expect(ticket.reload.status).to eq("open")
        expect(flash[:notice]).to be_present
      end

      it "keeps a non-backlog status unchanged" do
        ticket.update!(status: :in_progress)
        patch move_to_sprint_ticket_path(ticket, target: "current")
        expect(ticket.reload.sprint).to eq(current_sprint)
        expect(ticket.reload.status).to eq("in_progress")
      end

      it "alerts when the project has no active sprint" do
        current_sprint.update!(status: :completed)
        patch move_to_sprint_ticket_path(ticket, target: "current")
        expect(ticket.reload.sprint).to be_nil
        expect(flash[:alert]).to be_present
      end
    end

    context "target: next" do
      let!(:next_sprint) do
        create(:sprint, project: project,
               start_date: Date.current + 15, end_date: Date.current + 28)
      end
      let!(:ticket) { create(:ticket, project: project, status: :backlog) }

      it "assigns the upcoming sprint" do
        patch move_to_sprint_ticket_path(ticket, target: "next")
        expect(ticket.reload.sprint).to eq(next_sprint)
        expect(ticket.reload.status).to eq("open")
      end

      it "picks the earliest upcoming sprint when several exist" do
        later = create(:sprint, project: project,
                       start_date: Date.current + 40, end_date: Date.current + 54)
        patch move_to_sprint_ticket_path(ticket, target: "next")
        expect(ticket.reload.sprint).to eq(next_sprint)
        expect(ticket.reload.sprint).not_to eq(later)
      end

      it "alerts when the project has no upcoming sprint" do
        next_sprint.destroy
        patch move_to_sprint_ticket_path(ticket, target: "next")
        expect(ticket.reload.sprint).to be_nil
        expect(flash[:alert]).to be_present
      end
    end

    context "target: backlog" do
      let!(:sprint) { create(:active_sprint, project: project) }
      let!(:ticket) { create(:ticket, project: project, sprint: sprint, status: :in_progress) }

      it "clears the sprint and sets the status to backlog" do
        patch move_to_sprint_ticket_path(ticket, target: "backlog")
        expect(ticket.reload.sprint).to be_nil
        expect(ticket.reload.status).to eq("backlog")
        expect(flash[:notice]).to be_present
      end
    end

    context "with an unknown target" do
      it "leaves the ticket unchanged and alerts" do
        patch move_to_sprint_ticket_path(ticket, target: "bogus")
        expect(flash[:alert]).to be_present
      end
    end

    it "only moves the ticket within its own project's sprints" do
      create(:active_sprint, project: create(:project))
      patch move_to_sprint_ticket_path(ticket, target: "current")
      expect(ticket.reload.sprint).to be_nil
      expect(flash[:alert]).to be_present
    end
  end

  # ── Attachments panel on the ticket page ──────────────────────────────────
  describe "attachments panel" do
    it "lists the ticket's attachments" do
      ticket.attachments.attach(io: StringIO.new("a,b\n1,2"), filename: "report.csv", content_type: "text/csv")
      ticket.attachments.attach(io: StringIO.new("img"), filename: "mockup.png", content_type: "image/png")
      get ticket_path(ticket)
      expect(response.body).to include('id="attachments"')
      expect(response.body).to include("Attachments (2)")
      expect(response.body).to include("report.csv")
      expect(response.body).to include("mockup.png")
    end
  end

  # ── PATCH /tickets/:id/approve ─────────────────────────────────────────────
  describe "PATCH /tickets/:id/approve" do
    it "stamps approved_at" do
      expect(ticket.approved_at).to be_nil
      patch approve_ticket_path(ticket), headers: { "HTTP_REFERER" => ticket_path(ticket) }
      expect(ticket.reload.approved_at).to be_present
      expect(flash[:notice]).to include("approved")
    end
  end

  # ── Staged edit form ───────────────────────────────────────────────────────
  describe "staged edit form" do
    it "shows only the basics for an unapproved ticket (no estimation fields)" do
      get edit_ticket_path(ticket)
      expect(response.body).to include("Approve ticket")
      expect(response.body).not_to include("ticket_story_points")
    end

    it "shows estimation fields on the estimation section once approved but not yet estimated" do
      ticket.update!(approved_at: Time.current, story_points: nil, dev_estimate_hours: nil)
      get edit_ticket_path(ticket, section: "estimation")
      expect(response.body).to include("Refinement &amp; Estimation")
      expect(response.body).to include("ticket_story_points")
    end

    it "shows the tasks panel (not estimation fields) once estimated" do
      ticket.update!(approved_at: Time.current, story_points: 5, dev_estimate_hours: 8)
      get edit_ticket_path(ticket)
      expect(response.body).to include('id="tasks"')
      expect(response.body).to include("Generate tasks &amp; estimations")
      expect(response.body).not_to include("Refinement &amp; Estimation")
    end
  end

  # ── PATCH /tickets/:id/update_status ──────────────────────────────────────
  describe "PATCH /tickets/:id/update_status" do
    it "updates the ticket status and redirects back" do
      patch update_status_ticket_path(ticket, status: "in_review"),
            headers: { "HTTP_REFERER" => project_path(project) }
      expect(ticket.reload.status).to eq("in_review")
      expect(response).to redirect_to(project_path(project))
      expect(flash[:notice]).to be_present
    end

    it "can mark a ticket done" do
      patch update_status_ticket_path(ticket, status: "done")
      expect(ticket.reload.status).to eq("done")
    end

    it "rejects an unknown status and leaves the ticket unchanged" do
      original = ticket.status
      patch update_status_ticket_path(ticket, status: "not_a_status")
      expect(ticket.reload.status).to eq(original)
      expect(flash[:alert]).to be_present
    end
  end

  # ── Comments ──────────────────────────────────────────────────────────────
  describe "POST /tickets/:ticket_id/comments" do
    context "when user is an admin" do
      let(:user) { create(:user, role: :admin) }

      it "creates a comment and redirects back to ticket" do
        post ticket_comments_path(ticket), params: { comment: { body: "Great work!" } }
        expect(response).to redirect_to(ticket_path(ticket))
        expect(ticket.comments.last.body).to eq("Great work!")
      end

      it "rejects blank comments" do
        post ticket_comments_path(ticket), params: { comment: { body: "" } }
        expect(response).to redirect_to(ticket_path(ticket))
        expect(flash[:alert]).to include("blank")
      end
    end
  end
end
