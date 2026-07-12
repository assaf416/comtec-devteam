# Chat with AI — scoped to a project so the context (including the project's git
# repository) is always relevant. Reached from the project page.
class AiChatsController < ApplicationController
  before_action :set_project_from_param, only: %i[index create]
  before_action :set_session,            only: %i[show message]

  def index
    @sessions = project_sessions
    @session  = @sessions.first
  end

  def show
    @sessions = project_sessions
  end

  # Start a new chat for this project (optionally with a first message).
  def create
    @session = current_user.ai_chat_sessions.create!(project: @project, sprint: @project.current_sprint)
    converse!(@session, params[:message]) if params[:message].present?
    redirect_to ai_chat_path(@session)
  end

  def message
    converse!(@session, params[:message]) if params[:message].present?
    redirect_to ai_chat_path(@session, anchor: "bottom")
  end

  private

  def set_project_from_param
    @project = Project.find(params[:project_id])
  end

  def set_session
    @session = current_user.ai_chat_sessions.find(params[:id])
    @project = @session.project
  end

  def project_sessions
    current_user.ai_chat_sessions.where(project: @project).recent.limit(50)
  end

  # Append the user's message, call the local LLM with fresh project context.
  def converse!(session, text)
    session.ai_chat_messages.create!(role: "user", content: text.to_s.strip)
    session.update!(title: text.to_s.strip.truncate(60)) if session.title.blank?

    client  = Ai::OllamaClient.new
    context = Ai::ChatContextService.new(project: session.project, sprint: session.sprint).system_prompt
    history = session.ai_chat_messages.map { |m| { role: m.role, content: m.content } }

    begin
      reply = client.converse(messages: [ { role: "system", content: context } ] + history)
      session.update!(llm_model: client.model)
    rescue Ai::OllamaClient::Error => e
      reply = "⚠️ The local AI is unavailable right now (#{e.message}). Check that Ollama is running on the Mac mini."
    end

    session.ai_chat_messages.create!(role: "assistant", content: reply.presence || "(no response)")
  end
end
