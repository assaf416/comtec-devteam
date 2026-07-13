require 'rails_helper'

RSpec.describe "Mobile show screens", type: :request do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }

  before { sign_in user }

  describe "GET /mobile/project/:id" do
    it "shows the project with tickets, PRs, members, notes and comments sections" do
      ticket = create(:ticket, project: project, title: "Mobile ticket A")
      create(:pull_request, project: project, ticket: ticket, pr_number: 5, title: "PR five")
      Comment.create!(commentable: ticket, author: user, body: "a project-level discussion note")

      get mobile_project_path(project)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(project.name)
      expect(response.body).to include("Mobile ticket A")
      expect(response.body).to include("Pull Requests")
      expect(response.body).to include("Members")
      expect(response.body).to include("Notes")
      expect(response.body).to include("a project-level discussion note")
      # ticket links go to the mobile ticket screen
      expect(response.body).to include(mobile_ticket_path(ticket))
    end
  end

  describe "GET /mobile/ticket/:id" do
    it "shows the ticket with members, tasks, PRs and comments" do
      ticket = create(:ticket, project: project, assignee: user, title: "Detailed ticket")
      ticket.tasks.create!(description: "Wire up the controller")
      create(:pull_request, project: project, ticket: ticket, pr_number: 12, title: "Ticket PR")
      ticket.comments.create!(author: user, body: "looks good to me")

      get mobile_ticket_path(ticket)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Detailed ticket")
      expect(response.body).to include("Members")
      expect(response.body).to include("Wire up the controller")
      expect(response.body).to include("Tasks")
      expect(response.body).to include("looks good to me")
      expect(response.body).to include(user.display_name)
    end
  end

  describe "GET /mobile/tickets" do
    it "lists open tickets linking to the mobile ticket screen" do
      ticket = create(:ticket, project: project, assignee: user, status: :open, title: "Open one")
      get mobile_tickets_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(mobile_ticket_path(ticket))
    end
  end
end
