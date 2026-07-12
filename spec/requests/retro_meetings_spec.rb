require 'rails_helper'

RSpec.describe "RetroMeetings", type: :request do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }
  let(:dev)     { create(:user, name: "Dana Dev") }
  let!(:sprint) { create(:active_sprint, project: project, velocity: 30) }

  before { sign_in user }

  it "renders the retro with video bar, summary, trend charts and the team table" do
    create(:ticket, project: project, sprint: sprint, assignee: dev, owner: dev,
           status: :done, story_points: 5, dev_estimate_hours: 8, actual_hours: "8h", test_plan: "covered")

    get retro_meeting_path(sprint_id: sprint.id)

    expect(response).to have_http_status(:success)
    expect(response.body).to include("Sprint Retrospective")
    expect(response.body).to include("jitsi-frame")        # video bar
    expect(response.body).to include("This sprint")        # summary section
    expect(response.body).to include("Team performance")   # per-developer report
    expect(response.body).to include("Dana Dev")           # appears in the table
  end
end
