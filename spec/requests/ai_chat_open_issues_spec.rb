require "rails_helper"

RSpec.describe "AI chat — open issues from a proposal", type: :request do
  let(:user)    { create(:user) }
  let(:project) { create(:project, repo_url: "https://github.com/acme/widget") }
  let(:session) { create(:ai_chat_session, user: user, project: project) }

  before { sign_in user }

  it "opens GitHub issues from the latest proposal and confirms in the chat" do
    session.ai_chat_messages.create!(role: "assistant", content: "הצעתי מטלות")
    session.ai_chat_messages.create!(
      role: "proposal",
      content: { "tasks" => [ { "title" => "Login", "body" => "build it" },
                              { "title" => "Signup", "body" => "add it" } ] }.to_json
    )

    fake_gh = instance_double(GithubService)
    allow(GithubService).to receive(:new).and_return(fake_gh)
    allow(fake_gh).to receive(:create_issue).and_return({ "number" => 11 }, { "number" => 12 })

    expect {
      post open_issues_ai_chat_path(session)
    }.to change { session.ai_chat_messages.where(role: "proposal").count }.by(-1)

    expect(response).to redirect_to(ai_chat_path(session, anchor: "bottom"))
    follow_redirect!
    expect(response.body).to include("פתחתי 2 issues")
    expect(fake_gh).to have_received(:create_issue).twice
  end

  it "warns when the project has no GitHub repo_url" do
    project.update!(repo_url: "http://gitea.local/x/y")
    session.ai_chat_messages.create!(role: "proposal", content: { "tasks" => [] }.to_json)
    post open_issues_ai_chat_path(session)
    expect(flash[:alert]).to include("GitHub")
  end
end
