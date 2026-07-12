module Assistant
  # The chat-terminal agent. Slash-commands run deterministically against the
  # app's own data/services (so the terminal is useful even with no LLM running);
  # free text is routed to the local Ollama model with a graceful demo fallback.
  class Agent
    SYSTEM = <<~SYS.freeze
      You are the DevTeam assistant embedded in an on-prem engineering hub.
      Be concise and practical. You can mention that slash-commands like /review,
      /deploy, /report, /servers and /search run real actions in the app.
    SYS

    COMMANDS = {
      "/help"    => "show this help",
      "/review"  => "<pr#> — pre-merge analysis for a pull request",
      "/report"  => "team & delivery snapshot",
      "/servers" => "server health summary",
      "/deploy"  => "<tag> to <env> — how to roll out a build",
      "/search"  => "<text> — find tickets & PRs"
    }.freeze

    def initialize(user:)
      @user = user
    end

    def respond(text, history: [])
      t = text.to_s.strip
      return help if t.blank? || t == "/" || t.start_with?("/help")
      return run_command(t) if t.start_with?("/")

      llm(t, history)
    end

    private

    def run_command(text)
      cmd, *rest = text.sub(%r{\A/}, "").split(" ")
      arg = rest.join(" ").strip
      case cmd
      when "review"  then review(arg)
      when "report"  then report
      when "servers" then servers
      when "deploy"  then deploy_hint(arg)
      when "search"  then search(arg)
      else "Unknown command `/#{cmd}`. Type /help."
      end
    end

    def help
      lines = COMMANDS.map { |c, d| "  #{c.ljust(9)} #{d}" }
      "DevTeam assistant — commands:\n#{lines.join("\n")}\n\nOr just type a question and I'll ask the local model."
    end

    def review(arg)
      pr = PullRequest.find_by(pr_number: arg.to_i) || PullRequest.find_by(id: arg.to_i)
      return "No PR ##{arg} found." unless pr

      a = Git::MergeService.new.analyze(pr)
      checks = a.checks.map { |n, c| "  #{c[:ok] ? '✓' : '✗'} #{n} — #{c[:label]}" }.join("\n")
      "PR ##{pr.pr_number} “#{pr.title}” → #{a.state_label}\n#{checks}\nOpen cockpit: /pull_requests/#{pr.id}/cockpit"
    end

    def report
      sprints = Sprint.active.count
      open_t  = Ticket.where.not(status: %i[done closed]).count
      open_pr = PullRequest.where(status: %i[open review]).count
      deploys = Deployment.where(created_at: 7.days.ago..).count
      "Delivery snapshot:\n  • #{sprints} active sprint(s)\n  • #{open_t} open tickets\n  • #{open_pr} PRs awaiting review\n  • #{deploys} deployments in the last 7 days"
    end

    def servers
      rows = ServerHeartbeat.servers.map do |s|
        "  #{(s.server_name || s.ip_address).ljust(14)} #{s.health.upcase.ljust(8)} cpu #{s.cpu}%  mem #{s.mem}%  disk #{s.disk}%"
      end
      rows.any? ? "Servers:\n#{rows.join("\n")}" : "No servers reporting."
    end

    def deploy_hint(arg)
      "To deploy #{arg.presence || '<tag> to <env>'}: open the Deploy console at /deploy, pick the project, its CI image tag, the environment and a target server. Recent rollouts and rollback live at /releases."
    end

    def search(arg)
      return "Usage: /search <text>" if arg.blank?

      tix = Ticket.where("title LIKE ?", "%#{arg}%").limit(5)
      prs = PullRequest.where("title LIKE ?", "%#{arg}%").limit(5)
      out = []
      out << "Tickets:\n" + tix.map { |t| "  ##{t.id} #{t.title} (#{t.status})" }.join("\n") if tix.any?
      out << "Pull requests:\n" + prs.map { |p| "  ##{p.pr_number} #{p.title} (#{p.status})" }.join("\n") if prs.any?
      out.any? ? out.join("\n\n") : "Nothing found for “#{arg}”."
    end

    def llm(text, history)
      client = Ai::OllamaClient.new
      mapped = Array(history).last(20).map { |m| { role: m["role"] || m[:role], content: m["content"] || m[:content] } }
      mapped << { role: "user", content: text } unless mapped.last && mapped.last[:content] == text
      client.converse(messages: [ { role: "system", content: SYSTEM } ] + mapped)
    rescue Ai::OllamaClient::Error => e
      "⚠️ Local AI is offline (#{e.message}). Slash-commands still work — type /help to see them."
    end
  end
end
