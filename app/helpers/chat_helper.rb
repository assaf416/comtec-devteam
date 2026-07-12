module ChatHelper
  # Renders a chat message body with embedded reference chips and URL auto-linking.
  # Supported patterns:
  #   #T-123     → Ticket link
  #   #CI-123    → CI run link
  #   #D-123     → Deployment link
  #   #PR-123    → Pull Request link
  #   @username  → User mention highlight
  #   URLs       → Clickable links (open in new tab)
  def render_chat_body(text)
    # Start with HTML-escaped content to prevent XSS
    html = ERB::Util.html_escape(text)

    # Ticket refs: #T-123
    html = html.gsub(/#T-(\d+)/) do
      id = $1
      link_to("#T-#{id}", ticket_path(id), class: "chat-ref chat-ref-ticket")
    end

    # CI run refs: #CI-123
    html = html.gsub(/#CI-(\d+)/) do
      id = $1
      link_to("#CI-#{id}", ci_run_path(id), class: "chat-ref chat-ref-ci")
    end

    # Deployment refs: #D-123
    html = html.gsub(/#D-(\d+)/) do
      id = $1
      link_to("#D-#{id}", deployment_path(id), class: "chat-ref chat-ref-deploy")
    end

    # Pull request refs: #PR-123
    html = html.gsub(/#PR-(\d+)/) do
      id = $1
      link_to("#PR-#{id}", pull_request_path(id), class: "chat-ref chat-ref-pr")
    end

    # @mentions
    html = html.gsub(/@([\w.\-]+)/) do
      name = $1
      %(<span class="chat-ref chat-ref-mention">@#{ERB::Util.html_escape(name)}</span>)
    end

    # Auto-link URLs (not already inside an href)
    html = html.gsub(%r{(?<![="'])https?://[^\s<>"']+}) do |url|
      %(<a href="#{ERB::Util.html_escape(url)}" target="_blank" rel="noopener noreferrer" class="has-text-link">#{ERB::Util.html_escape(url)}</a>)
    end

    html.html_safe
  end

  def ci_status_dot(status)
    css = case status.to_s
    when "passed"  then "passed"
    when "failed"  then "failed"
    when "running" then "running"
    when "pending" then "pending"
    else "none"
    end
    content_tag(:span, "", class: "ci-status-dot #{css}")
  end
end
