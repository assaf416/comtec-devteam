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
    it "shows the common-query links with the index marked active" do
      get all_tickets_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(my_tickets_path)
      expect(response.body).to include(late_tickets_path)
      expect(response.body).to include(backlog_tickets_path)
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

  # ── Sidebar: Main / Tools / Tables groups; GitHub group is project-scoped ──
  describe "sidebar navigation" do
    it "shows the Main and Tools groups and hides the project-only GitHub group" do
      get today_path
      expect(response.body).to include(I18n.t("sidebar.main_label"))
      expect(response.body).to include(I18n.t("sidebar.tools_label"))
      expect(response.body).to include(I18n.t("nav.my_day"))
      expect(response.body).to include(I18n.t("nav.time_logging"))
      # The old sidebar sections (CI/DevOps, Reports) and the Meetings nav item
      # are gone from the sidebar.
      expect(response.body).not_to include(I18n.t("sidebar.ci_label"))
      expect(response.body).not_to include(I18n.t("sidebar.reports_label"))
      expect(response.body).not_to match(%r{sidebar-nav-item[^"]*"[^>]*>\s*<span class="nav-icon">📅</span>})
      # GitHub group only appears inside a project context
      expect(response.body).not_to include(I18n.t("sidebar.github_label"))
    end

    it "shows the project-scoped GitHub + AI Agent groups on a project page" do
      project = create(:project, repo_url: "https://github.com/acme/widget")
      get project_path(project)
      expect(response.body).to include(I18n.t("sidebar.github_label"))
      expect(response.body).to include(I18n.t("nav.github_issues"))
      expect(response.body).to include(I18n.t("nav.ai_agent"))
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

  # ── Tickets are read-only mirrors of GitHub issues ────────────────────────
  describe "read-only ticket show" do
    it "links out to the GitHub issue when synced" do
      ticket.update_columns(github_issue_number: 42, github_url: "https://github.com/acme/widget/issues/42")
      get ticket_path(ticket)
      expect(response.body).to include("https://github.com/acme/widget/issues/42")
      expect(response.body).to include("issue #42")
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
