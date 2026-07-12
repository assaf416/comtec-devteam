require 'rails_helper'

RSpec.describe "Ceremonies", type: :request do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }
  let(:dev)     { create(:user, name: "Dana Dev") }
  let!(:sprint) { create(:active_sprint, project: project, goals: "Ship it") }

  before { sign_in user }

  describe "GET /ceremonies/planning" do
    it "renders capacity, needs-estimation and the backlog with a pull action" do
      create(:ticket, project: project, status: :backlog, title: "Backlog item")
      create(:ticket, project: project, sprint: sprint, assignee: dev, story_points: nil)

      get ceremony_path("planning")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Sprint Planning")
      expect(response.body).to include("jitsi-frame")
      expect(response.body).to include("Backlog item")
      expect(response.body).to include(move_to_sprint_ticket_path(Ticket.find_by(title: "Backlog item"), target: "current"))
    end
  end

  describe "GET /ceremonies/refinement" do
    it "lists tickets that need refinement" do
      create(:ticket, project: project, sprint: sprint, title: "Vague ticket",
             description: nil, story_points: nil, dev_estimate_hours: nil, status: :open)
      get ceremony_path("refinement")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Backlog Refinement")
      expect(response.body).to include("Vague ticket")
    end
  end

  describe "GET /ceremonies/review" do
    it "shows completed work to demo" do
      create(:ticket, project: project, sprint: sprint, title: "Shipped feature", status: :done)
      get ceremony_path("review")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Sprint Review")
      expect(response.body).to include("Shipped feature")
    end
  end

  it "does not route an unknown ceremony kind" do
    get "/ceremonies/bogus"
    expect(response).to have_http_status(:not_found)
  end
end
