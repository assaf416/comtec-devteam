#!/usr/bin/env ruby
# frozen_string_literal: true

# ci/ai_review.rb — On-prem AI code review via Ollama
# Usage: ruby ci/ai_review.rb [base_branch]
#
# Sends the git diff to a local Ollama LLM and posts
# review comments back to Gitea via API.

require "net/http"
require "json"
require "uri"

OLLAMA_URL     = ENV.fetch("OLLAMA_URL",   "http://localhost:11434")
OLLAMA_MODEL   = ENV.fetch("OLLAMA_MODEL", "qwen2.5-coder:32b")
GITEA_URL      = ENV.fetch("GITEA_URL",    "http://gitea:3001")
GITEA_TOKEN    = ENV.fetch("GITEA_TOKEN",  "")
MAX_DIFF_LINES = 500

base_branch = ARGV[0] || "main"

# ── 1. Get the diff ──────────────────────────────────────────────
diff = `git diff #{base_branch}...HEAD --unified=3 -- '*.rb' '*.cs' '*.ts' '*.js' '*.vb' '*.erb' '*.razor'`
if diff.strip.empty?
  puts "No code changes to review."
  exit 0
end

lines = diff.lines
if lines.size > MAX_DIFF_LINES
  diff = lines.first(MAX_DIFF_LINES).join
  diff += "\n... (diff truncated to #{MAX_DIFF_LINES} lines)\n"
end

# ── 2. Build the prompt ──────────────────────────────────────────
prompt = <<~PROMPT
  You are a senior code reviewer. Review the following git diff and provide
  concise, actionable feedback. Focus on:
  - Bugs and logic errors
  - Security vulnerabilities (OWASP Top 10)
  - Performance issues
  - Code style and readability
  - Missing error handling or edge cases

  Format your response as a numbered list of findings. For each finding:
  - State the file and approximate line
  - Describe the issue
  - Suggest a fix

  If the code looks good, say "LGTM — no issues found."

  ```diff
  #{diff}
  ```
PROMPT

# ── 3. Call Ollama ────────────────────────────────────────────────
uri  = URI("#{OLLAMA_URL}/api/generate")
body = { model: OLLAMA_MODEL, prompt: prompt, stream: false }
http = Net::HTTP.new(uri.host, uri.port)
http.read_timeout = 300

req = Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")
req.body = JSON.generate(body)

puts "Sending diff to #{OLLAMA_MODEL} for review..."
res = http.request(req)

unless res.is_a?(Net::HTTPSuccess)
  warn "Ollama error: #{res.code} #{res.body}"
  exit 1
end

review = JSON.parse(res.body)["response"]
puts "\n#{"=" * 40}\n  AI Code Review\n#{"=" * 40}\n\n#{review}\n"

# ── 4. Post to Gitea PR (if in CI with PR context) ───────────────
pr_number = ENV["GITEA_PR_NUMBER"] || ENV["CI_PULL_REQUEST"]
repo      = ENV["GITEA_REPO"]

if pr_number && repo && !GITEA_TOKEN.empty?
  comment_uri = URI("#{GITEA_URL}/api/v1/repos/#{repo}/issues/#{pr_number}/comments")
  comment_body = "## 🤖 AI Code Review\n\n#{review}\n\n---\n*Reviewed by #{OLLAMA_MODEL} (on-prem)*"

  comment_req = Net::HTTP::Post.new(comment_uri.path, {
    "Content-Type"  => "application/json",
    "Authorization" => "token #{GITEA_TOKEN}"
  })
  comment_req.body = JSON.generate({ body: comment_body })

  comment_http = Net::HTTP.new(comment_uri.host, comment_uri.port)
  comment_res  = comment_http.request(comment_req)

  if comment_res.is_a?(Net::HTTPSuccess)
    puts "Review posted to Gitea PR ##{pr_number}"
  else
    warn "Failed to post to Gitea: #{comment_res.code}"
  end
else
  puts "(No PR context — review printed to stdout only)"
end
