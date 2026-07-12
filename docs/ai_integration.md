# DevTeam Hub — AI Agent Integration (Local LLM)

> **Version:** 1.0
> **Last updated:** June 5, 2026
> **Applies to:** DevTeam Hub 2.x

---

## 1. Overview

DevTeam Hub integrates a **local Large Language Model** into the team's everyday
workflow and CI process. The model runs **entirely on-premises** on a dedicated
**Mac mini** using [Ollama](https://ollama.com), and DevTeam Hub talks to it over
a plain HTTP REST API on the LAN.

Nothing — no ticket text, no source diffs, no test files — ever leaves the local
network. This is the whole point: teams get modern AI assistance (code review,
ticket triage, estimation analytics, solution suggestions) **without** sending
proprietary code or customer data to a third-party SaaS.

```
┌────────────────────┐        HTTP (LAN, no internet)        ┌────────────────────┐
│   DevTeam Hub      │  ───────────────────────────────────▶ │   Mac mini         │
│   (Rails 8 app)    │   POST /api/chat  { model, messages } │   ollama serve     │
│                    │ ◀─────────────────────────────────── │   llama3.1 / etc.  │
│  Ai::OllamaClient  │        { message: { content } }        │   (local models)   │
└────────────────────┘                                        └────────────────────┘
```

---

## 2. Why a local LLM (the on-prem problem it solves)

| On-prem pain | How the local LLM helps |
|---|---|
| Can't send source code to OpenAI/Anthropic for review | The model runs on your own Mac mini — code never leaves the LAN |
| Air-gapped / regulated environments | No outbound internet dependency at inference time |
| Per-seat SaaS AI licensing costs | One Mac mini serves the whole team, flat cost |
| Data residency / customer NDAs | All prompts and responses stay on infrastructure you control |
| CI needs deterministic, always-available AI | A pinned local model with no rate limits or vendor outages |

---

## 3. Architecture

| Component | File | Responsibility |
|---|---|---|
| REST client | `app/services/ai/ollama_client.rb` | Low-level Faraday client for Ollama (`/api/chat`, `/api/generate`, `/api/tags`) |
| Base service | `app/services/ai/base_service.rb` | Lifecycle: create `AiReview` → call LLM → parse verdict/score → persist |
| Service objects | `app/services/ai/*_service.rb` | One per AI capability (see §5) |
| Controller | `app/controllers/tools/ai_controller.rb` | HTTP entry points under `/tools/ai/*` |
| Persistence | `app/models/ai_review.rb` (`ai_reviews` table) | Stores every run, auditable & linkable |
| UI | sidebar "AI Agent" section, ticket page panel, sprint-page live frame | Triggers + results |

### Why no extra gem?

The integration reuses **Faraday**, already in the Gemfile for the Gitea/Jenkins
integrations. Ollama's API is plain JSON over HTTP, so no `ruby-openai` /
`ollama-ai` gem is required. (You *can* swap in `ruby-openai` pointed at Ollama's
OpenAI-compatible endpoint at `/v1` if you prefer that SDK — `Ai::OllamaClient` is
the single seam to change.)

### The `AiReview` record

Every service call persists exactly one `ai_reviews` row:

| Column | Meaning |
|---|---|
| `kind` | which service produced it (`ticket_quality`, `code_review`, …) |
| `status` | `pending` / `running` / `completed` / `failed` |
| `reviewable_type` / `reviewable_id` | polymorphic link to the Ticket / Sprint / Project |
| `llm_model` | model used, e.g. `llama3.1:8b` |
| `verdict` | machine verdict parsed from the reply: `pass` / `needs_work` / `fail` |
| `score` | optional 0–100 score |
| `summary` | one-line summary |
| `body` | full Markdown response |
| `prompt` | exact prompt sent (audit/debug) |
| `duration_ms` | round-trip time |
| `error_message` | populated when `status = failed` |

Because results are stored, the UI can show **AI Reports**, **Recent Review
Results**, and **Recent Test Reviews**, and every run is replayable and auditable.

---

## 4. Setup

### 4.1 On the Mac mini

```bash
# Install Ollama (https://ollama.com/download)
brew install ollama          # or the .dmg installer

# Run the server, listening on all interfaces so the Rails host can reach it
OLLAMA_HOST=0.0.0.0:11434 ollama serve

# Pull the model(s) you want to use
ollama pull llama3.1         # general purpose
ollama pull qwen2.5-coder    # stronger for code review (optional)
```

### 4.2 On the DevTeam Hub host

Set the environment variables (see `.env.example`):

```bash
OLLAMA_URL=http://your-mac-mini.local:11434   # host:port of the Mac mini
OLLAMA_MODEL=llama3.1                          # default model for reviews
OLLAMA_TIMEOUT=300                             # seconds to wait for a completion
```

The **AI Reports** page (`/tools/ai`) shows a live connection badge — green when
Ollama is reachable, plus the list of installed models — so you can confirm the
link without leaving the app.

---

## 5. The AI Services (in detail)

Each service has a system prompt that asks the model to emit a leading
`VERDICT:` and `SCORE:` line followed by Markdown findings; the base service
parses those into the `verdict`/`score` columns.

### 5.1 Ticket Story-telling / Readiness check
- **Service:** `Ai::TicketQualityService` · **kind:** `ticket_quality`
- **Endpoint:** `POST /tools/ai/ticket_quality?ticket_id=…`
- **UI:** "✅ Check readiness" button on the ticket page.
- **What it does:** Judges the ticket against a Definition of Ready — clear story
  ("As a … I want … so that …"), testable acceptance criteria, reproduction steps
  for bugs, and a sane estimate.
- **Action on result:** if the verdict is **not** `pass`, the ticket is
  automatically **reassigned to its owner**, moved back to `open`, and a comment
  with the AI summary is posted — closing the loop so badly-written tickets don't
  reach development.

### 5.2 Code review (Go / Ruby / C# / Node)
- **Service:** `Ai::CodeReviewService` · **kind:** `code_review`
- **Endpoint:** `POST /tools/ai/code_review` (params: `diff`, optional `language`, optional `ticket_id`)
- **UI:** "🔍 Code review" form on the ticket page (paste a diff, pick a language).
- **What it does:** Reviews a diff for correctness bugs, security, performance and
  language idioms, applying the right lint expectations per language:
  - **Go** — gofmt, go vet, golangci-lint, idiomatic error handling, context use
  - **Ruby** — RuboCop (rails-omakase), N+1 queries, service objects
  - **C#** — dotnet format, Roslyn analyzers, async/await, IDisposable, nullable refs
  - **Node** — ESLint + Prettier, async/await, unhandled rejections, input validation
- Findings are grouped into **Blocking**, **Suggestions**, **Lint / Style**.
- **CI use:** call the endpoint from a CI step (with an API token) to get an
  automated review comment on every push.

### 5.3 Cucumber test review
- **Service:** `Ai::TestReviewService` · **kind:** `test_review`
- **Endpoint:** `POST /tools/ai/test_review` (params: `feature`, optional `ticket_id`)
- **UI:** "🧪 Test review" form on the ticket page (paste a `.feature` file).
- **What it does:** Reviews Gherkin for clarity, determinism (no flaky/sleep-based
  steps), structure (Background, Scenario Outline, tags), step reuse — and most
  importantly **suggests missing scenarios** (edge cases, negative paths,
  permissions, i18n, boundaries) written as ready-to-paste Gherkin.

### 5.4 Estimation accuracy (estimated vs actual)
- **Service:** `Ai::EstimationAnalysisService` · **kind:** `estimation_analysis`
- **Endpoint:** `POST /tools/ai/estimation_analysis?sprint_id=…` (or `project_id`)
- **UI:** "📊 AI Estimation" button on the sprint page.
- **What it does:** DevTeam Hub computes a table of completed tickets with
  `dev_estimate_hours` vs actual hours (parsed from `actual_hours`, e.g. "2d 4h"),
  then the model analyses **systematic bias**, **per-developer patterns**, which
  complexity levels drift most, and gives concrete coaching. Produces an accuracy
  **score** 0–100.

### 5.5 Sprint status analysis (live)
- **Service:** `Ai::SprintAnalysisService` · **kind:** `sprint_analysis`
- **Endpoint:** `GET/POST /tools/ai/sprint_analysis?sprint_id=…`
- **UI:** Renders **live** on the sprint page via a lazy Turbo Frame; a "Refresh"
  button re-runs it.
- **What it does:** From the ticket snapshot (statuses, points, assignees,
  days-remaining) it assesses whether the sprint is on track, surfaces risks
  (too much WIP, work stuck in review, unstarted high-priority items), checks
  workload balance, and names the single most important next step. Health
  **score** 0–100, verdict `pass` (on track) / `needs_work` (at risk) / `fail`.

### 5.6 Solution suggestion
- **Service:** `Ai::SolutionSuggestionService` · **kind:** `solution_suggestion`
- **Endpoint:** `POST /tools/ai/solution_suggestion?ticket_id=…`
- **UI:** "💡 Suggest solution" button on the ticket page.
- **What it does:** Reads the ticket and proposes a pragmatic implementation
  approach — steps, likely files/components, edge cases and risks, and which tests
  to add. If the ticket is too vague, it lists the questions to ask the owner.

### 5.7 Fix that bug
- **Service:** `Ai::BugFixService` · **kind:** `bug_fix`
- **Endpoint:** `POST /tools/ai/fix_bug?ticket_id=…`
- **UI:** "🐛 Fix that bug" button on the ticket page.
- **What it does:** Reads a bug ticket (description + reproduction steps), reasons
  about the **most likely root cause**, and proposes a concrete, minimal fix —
  with code where helpful, tests to add, and risks. Confidence **score** 0–100;
  verdict `fail` means there isn't enough information to diagnose (and lists what's
  missing).

### 5.8 Generate tasks & estimations
- **Service:** `Ai::TaskBreakdownService` · **kind:** `task_breakdown`
- **Endpoint:** `POST /tools/ai/generate_tasks?ticket_id=…`
- **UI:** "🧩 Generate tasks & estimations" button on the ticket page.
- **What it does:** Breaks a story into precise, independently estimable **Task**
  records (see §5a). Crucially, it **calibrates the time estimates against the
  project's historical estimate-vs-actual data** — if the team consistently
  underestimates, the suggested estimates skew upward. The model returns a
  parseable `TASKS:` block (`- [4h] description`) which the controller turns into
  `Task` rows attached to the ticket.

### 5.9 Generate status presentation
- **Service:** `Ai::StatusPresentationService` · **kind:** `status_presentation`
- **Endpoint:** `POST /projects/:project_id/documents/generate?kind=presentation`
- **UI:** "🤖 Status Presentation" button in the project page Documents card (and on the project's Documents index).
- **What it does:** Gathers the project's live metrics (tickets by status, task
  progress & estimates, active sprint, CI pass rate, deployments, milestones) and
  writes a slide-style Markdown **status presentation**, saved as a `presentation`
  Document you can edit.

### 5.10 Generate specification document
- **Service:** `Ai::SpecDocumentService` · **kind:** `spec_document`
- **Endpoint:** `POST /projects/:project_id/documents/generate?kind=spec` (optional `topic`)
- **UI:** "🤖 Generate Spec" (with an optional focus field) in the project Documents area.
- **What it does:** Derives a structured **specification** (overview, goals,
  functional requirements from the project's user stories, non-functional
  requirements, architecture notes, acceptance criteria, out-of-scope, open
  questions), saved as a `spec` Document.

### 5.11 Chat with AI (project-scoped assistant)
- **Controller:** `AiChatsController` · **models:** `AiChatSession` / `AiChatMessage`
- **Endpoint:** `/projects/:project_id/ai_chats` (opened from the project page)
- **Context:** `Ai::ChatContextService` builds the system prompt from the project's
  **git repository (repo URL + branch), tickets, active sprint, recent team chat
  messages, documents, recent code (PR diffs)** and a **per-developer performance
  summary** (delivery speed + estimation accuracy).
- **What it does:** an OpenAI-style chat (sessions on the left, wide input bar).
  Because the context includes the team-performance summary and sprint metrics, it
  can answer natural-language questions such as:
  - *"Who is the fastest delivering developer?"* (lowest avg hours per delivered ticket)
  - *"Who has the best estimations?"* (highest estimate-vs-actual accuracy)
  - *"What's the current sprint status?"* (progress, risks, next step)
  It also drafts specs, risk-management docs and test plans on request. Multi-turn
  via `Ai::OllamaClient#converse`. Degrades gracefully when the LLM is offline.

### 5a. Tasks — story breakdown & progress

Independent of the AI, every **story** ticket owns a list of **Tasks**
(`app/models/task.rb`, `tasks` table). A task has a `description`, an `estimation`
and an `actual` (free-form like `4h` / `1d`), plus `started_at` / `completed_at`
timestamps from which its status (`not_started` / `in_progress` / `completed`) is
derived.

- **Auto-creation:** when a story ticket is created, DevTeam Hub seeds a single
  task named after the story, so the team can break it down immediately.
- **Why tasks:** it's easier to estimate a small slice of a story than the whole
  thing, and `Ticket#task_progress` derives the story's **progress** (completed /
  total → percentage) shown on the ticket page.
- **AI breakdown:** "🧩 Generate tasks & estimations" (§5.8) fills this list
  automatically with calibrated estimates.

---

## 6. Where to find it in the UI

- **Sidebar → AI Agent**
  - **AI Reports** (`/tools/ai`) — connection status, per-service counts, recent runs, recent failures.
  - **Recent Review Results** (`/tools/ai/reviews`) — all code reviews.
  - **Recent Test Reviews** (`/tools/ai/test_reviews`) — all cucumber test reviews.
- **Ticket page → 🤖 AI Agent panel** — readiness check, suggest solution,
  🐛 fix that bug, 🧩 generate tasks & estimations, code review, test review.
  The ticket also shows a **🧩 Tasks** panel with completion progress.
- **Sprint page** — a live AI sprint-analysis panel (auto-loads) + a 📊 AI Estimation button.

---

## 7. Calling the services from CI / scripts

Every endpoint is a normal authenticated POST. From a CI job, authenticate with a
DevTeam Hub API token and call, for example:

```bash
curl -X POST "$DEVTEAM_URL/tools/ai/code_review" \
     -H "Cookie: $SESSION" \
     --data-urlencode "language=go" \
     --data-urlencode "diff@-" < my.diff
```

The run is stored as an `AiReview`; the response redirects to its result page.
(For headless CI, prefer driving the `Ai::*Service` objects directly from a
rake task or a small API endpoint guarded by the existing `/api/v1` token auth.)

---

## 8. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| AI Reports shows **Ollama offline** | `ollama serve` not running, or `OLLAMA_URL` wrong / firewalled. Test with `curl $OLLAMA_URL/api/tags`. |
| Reviews are slow on first run | The model is loading into memory; subsequent calls are fast. Raise `OLLAMA_TIMEOUT`. |
| `status = failed` on a review | The `error_message` column / dashboard shows why (timeout, model not pulled, connection refused). |
| Verdict/score blank | The model didn't emit the `VERDICT:`/`SCORE:` header; the full text is still in the body. Use a stronger/instruction-tuned model. |
| Model not found | `ollama pull <model>` on the Mac mini; set `OLLAMA_MODEL` to a model in `ollama list`. |

---

## 9. Testing

The full flow is covered by `features/ai_agent.feature`. The Ollama client is
stubbed in `features/support/ai_support.rb` so the suite runs offline and
deterministically — no Mac mini required in CI.

```bash
bundle exec cucumber features/ai_agent.feature
```

---

## 10. Roadmap — more AI services to add

Ideas that fit the same `Ai::BaseService` + `AiReview` pattern:

1. **PR summarizer** — auto-write a PR description from the diff + linked ticket.
2. **Release notes / changelog** — summarize merged tickets per milestone.
3. **Standup digest** — per-developer "yesterday / today / blockers" from ticket activity.
4. **CI failure triage** — read failing build logs/test output and suggest the likely cause + fix.
5. **Duplicate ticket detection** — embeddings (`/api/embeddings`) to flag near-duplicate tickets/bugs.
6. **Commit-message linter** — check messages against Conventional Commits and ticket linkage.
7. **Retro assistant** — cluster sprint comments into themes and propose action items.
8. **Security review** — scan a diff for OWASP-style issues (complements Brakeman).
9. **Documentation drift** — flag when code changes but the linked doc/test plan didn't.
10. **Customer reply drafting** — draft a support reply from a customer ticket thread (human-approved).
11. **Estimation assistant** — suggest a story-point estimate for a new ticket from historical data.
12. **Meeting notes summarizer** — turn a meeting transcript/recording into action items + owners.
