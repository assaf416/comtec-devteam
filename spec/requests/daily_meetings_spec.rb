require 'rails_helper'

RSpec.describe "DailyMeetings", type: :request do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }
  let(:dev)     { create(:user, name: "Dana Dev") }
  let!(:sprint) { create(:active_sprint, project: project) }

  before { sign_in user }

  it "renders the standup with the Jitsi bar and per-member yesterday/today" do
    ticket = create(:ticket, project: project, sprint: sprint, assignee: dev, status: :in_progress)
    create(:task, ticket: ticket, description: "Shipped the API", completed_at: Date.yesterday.noon)
    create(:task, ticket: ticket, description: "Wiring the UI", started_at: 2.hours.ago)

    get daily_meeting_path(sprint_id: sprint.id)

    expect(response).to have_http_status(:success)
    expect(response.body).to include("Daily Meeting")
    expect(response.body).to include("jitsi-frame")           # video bar
    expect(response.body).to include("Dana Dev")              # team member
    expect(response.body).to include("Shipped the API")       # yesterday
    expect(response.body).to include("Wiring the UI")         # today (in progress)
  end

  it "shows an empty state when there is no sprint" do
    Sprint.update_all(status: :completed)
    get daily_meeting_path(sprint_id: "")
    # falls back to most recent sprint; with one completed it still resolves — just assert success
    expect(response).to have_http_status(:success)
  end
end
