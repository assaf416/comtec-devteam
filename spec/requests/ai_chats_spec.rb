require 'rails_helper'

RSpec.describe "AiChats", type: :request do
  let(:user)     { create(:user) }
  let!(:project) { create(:project, repo_url: "http://gitea.local/devteam/print-server") }
  before { sign_in user }

  describe "GET /projects/:project_id/ai_chats" do
    it "renders the project-scoped chat page with recommendations" do
      get project_ai_chats_path(project)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("צ'אט עם סוכן")
      expect(response.body).to include("הצע פתרון ל-issue")
      expect(response.body).to include('data-controller="ai-chat"')
    end
  end

  describe "POST /projects/:project_id/ai_chats" do
    it "creates a session tied to the project and stores the exchange" do
      allow_any_instance_of(Ai::OllamaClient).to receive(:converse).and_return("Here is the spec…")

      expect {
        post project_ai_chats_path(project), params: { message: "Generate a spec" }
      }.to change(AiChatSession, :count).by(1)

      session = AiChatSession.last
      expect(session.project).to eq(project)
      expect(session.ai_chat_messages.pluck(:role)).to eq(%w[user assistant])
      expect(response).to redirect_to(ai_chat_path(session))
    end
  end

  describe "POST /ai_chats/:id/message" do
    let(:session) { user.ai_chat_sessions.create!(project: project) }

    it "appends the reply from the local LLM" do
      allow_any_instance_of(Ai::OllamaClient).to receive(:converse).and_return("The sprint is on track.")
      expect {
        post message_ai_chat_path(session), params: { message: "How is the sprint?" }
      }.to change { session.ai_chat_messages.count }.by(2)
      expect(session.ai_chat_messages.last.content).to include("on track")
    end

    it "degrades gracefully when the LLM is offline" do
      allow_any_instance_of(Ai::OllamaClient).to receive(:converse)
        .and_raise(Ai::OllamaClient::Error, "connection refused")
      post message_ai_chat_path(session), params: { message: "hi" }
      expect(session.ai_chat_messages.last.content).to include("אינו זמין")
    end

    it "does not leak another user's session" do
      other = create(:user).ai_chat_sessions.create!(project: project)
      post message_ai_chat_path(other), params: { message: "hi" }
      expect(response).to have_http_status(:not_found)
      expect(other.ai_chat_messages).to be_empty
    end
  end

  describe "context service uses the project's git repo" do
    it "includes the repo URL and recent code as code context" do
      ctx = Ai::ChatContextService.new(project: project).context_body
      expect(ctx).to include("http://gitea.local/devteam/print-server")
      expect(ctx).to include(project.name)
    end

    it "includes per-developer delivery speed + estimation accuracy" do
      dev = create(:user, name: "Fast Dev")
      create(:ticket, project: project, assignee: dev, status: :done,
             dev_estimate_hours: 8, actual_hours: "8h")
      ctx = Ai::ChatContextService.new(project: project).context_body
      expect(ctx).to include("Team performance")
      expect(ctx).to include("Fast Dev")
      expect(ctx).to include("estimation accuracy")
    end
  end

  describe "project page links to its chat" do
    it "shows a Chat with AI button" do
      get project_path(project)
      expect(response.body).to include(project_ai_chats_path(project))
      expect(response.body).to include("Chat with AI")
    end
  end
end
