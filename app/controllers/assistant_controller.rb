# The AI chat terminal — a global, agentic console that drives the app's
# services via slash-commands and answers free text with the local LLM.
# Transcript lives in the session (no persistence needed for a terminal).
class AssistantController < ApplicationController
  def index
    @messages = transcript
  end

  def message
    text = params[:message].to_s.strip
    if text.present?
      push("user", text)
      reply = Assistant::Agent.new(user: current_user).respond(text, history: transcript)
      push("assistant", reply)
    end
    redirect_to assistant_path(anchor: "bottom")
  end

  def clear
    session[:assistant_transcript] = []
    redirect_to assistant_path
  end

  private

  def transcript
    session[:assistant_transcript] ||= []
  end

  def push(role, content)
    session[:assistant_transcript] = (transcript + [ { "role" => role, "content" => content } ]).last(40)
  end
end
