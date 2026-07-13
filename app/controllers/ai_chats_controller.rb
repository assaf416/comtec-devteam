# Chat with AI — scoped to a project so the context (including the project's git
# repository) is always relevant. Reached from the project page.
class AiChatsController < ApplicationController
  before_action :set_project_from_param, only: %i[index create]
  before_action :set_session,            only: %i[show message open_issues]

  def index
    @sessions = project_sessions
    @session  = @sessions.first
  end

  def show
    @sessions = project_sessions
  end

  # Start a new chat for this project (optionally with a first message).
  def create
    @session = current_user.ai_chat_sessions.create!(project: @project)
    converse!(@session, params[:message]) if params[:message].present?
    redirect_to ai_chat_path(@session)
  end

  def message
    converse!(@session, params[:message]) if params[:message].present?
    redirect_to ai_chat_path(@session, anchor: "bottom")
  end

  # Approve a task-list proposal and open the tasks as GitHub issues.
  def open_issues
    proposal = @session.ai_chat_messages.where(role: "proposal").order(:created_at).last
    return redirect_to(ai_chat_path(@session), alert: "אין הצעת מטלות לאישור.") unless proposal

    tasks = (JSON.parse(proposal.content)["tasks"] rescue [])
    project = @session.project
    owner, repo = GithubService.repo_parts(project&.repo_url)
    unless owner && repo && GithubService.github_url?(project&.repo_url)
      return redirect_to ai_chat_path(@session), alert: "לפרויקט אין כתובת GitHub תקינה לפתיחת issues."
    end

    gh = GithubService.new
    opened = tasks.filter_map do |tk|
      gh.create_issue(repo_owner: owner, repo_name: repo, title: tk["title"], body: tk["body"])
    end
    proposal.destroy # consumed — prevent double-opening

    summary = opened.any? ? "פתחתי #{opened.size} issues ב-GitHub: #{opened.map { |i| "##{i['number']}" }.join(', ')}" \
                          : "לא נפתחו issues (בדוק את חיבור ה-GitHub וה-token)."
    @session.ai_chat_messages.create!(role: "assistant", content: summary)
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

  # Append the user's message, then either run a matching AI skill or fall back
  # to a normal project-context conversation — all on the local LLM.
  def converse!(session, text)
    session.ai_chat_messages.create!(role: "user", content: text.to_s.strip)
    session.update!(title: text.to_s.strip.truncate(60)) if session.title.blank?

    client = Ai::OllamaClient.new

    begin
      result = Ai::ChatSkillRouter.new(project: session.project, user: current_user, client: client).route(text)
      session.update!(llm_model: client.model)

      if result.handled
        session.ai_chat_messages.create!(role: "assistant", content: result.reply.presence || "(no response)")
        session.ai_chat_messages.create!(role: "proposal", content: result.proposal.to_json) if result.proposal.present?
      else
        context = Ai::ChatContextService.new(project: session.project).system_prompt
        history = session.ai_chat_messages.where(role: %w[user assistant])
                         .map { |m| { role: m.role, content: m.content } }
        reply = client.converse(messages: [ { role: "system", content: context } ] + history)
        session.ai_chat_messages.create!(role: "assistant", content: reply.presence || "(no response)")
      end
    rescue Ai::OllamaClient::Error => e
      session.ai_chat_messages.create!(
        role: "assistant",
        content: "⚠️ ה-AI המקומי אינו זמין כרגע (#{e.message}). ודא ש-Ollama רץ על ה-Mac mini."
      )
    end
  end
end
