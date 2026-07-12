# DevTeam Hub

A **fully on-premises, self-hosted** agile project management and DevOps orchestration platform.
DevTeam Hub combines issue tracking, sprint planning, CI/CD visibility, team ceremonies, a customer
support portal, **and a local AI agent** in one place — built for teams running their own Git
(Gitea) and CI (Jenkins) infrastructure rather than relying on SaaS providers.

## Why on-premises
  
DevTeam Hub is built for teams that **cannot or will not** put their work on third-party SaaS — for
data-residency, NDA, air-gapped, or cost reasons. Everything runs on infrastructure you control:

- **No SaaS lock-in** — replaces Jira + Confluence + Freshdesk with one self-hosted app.
- **Your Git & CI** — integrates with self-hosted **Gitea** and **Jenkins**, not GitHub/GitLab cloud.
- **Your data stays put** — tickets, code, customer data, and now **AI inference** never leave the LAN.
- **Flat cost** — one deployment (plus one Mac mini for AI) serves the whole team; no per-seat fees.

## 🤖 Local AI agent (no cloud)

DevTeam Hub embeds a **local LLM running on an on-prem Mac mini** (via [Ollama](https://ollama.com)),
reached over a plain REST API on the LAN. **No code, ticket text, or customer data is ever sent to an
external AI provider.** The AI agent powers these services, all stored as auditable `AiReview` records:

1. **Ticket readiness** — verifies story-telling / Definition of Ready and **auto-reassigns
   poorly-written tickets back to their owner**.
2. **Code review** — reviews diffs for bugs, security, lint and best practice across **Go / Ruby / C# / Node**.
3. **Cucumber test review** — critiques `.feature` files and suggests **missing scenarios**.
4. **Estimation analytics** — estimated vs actual delivery time, with per-developer coaching.
5. **Live sprint analysis** — real-time sprint-health read rendered on the sprint page.
6. **Solution suggestions** — reads a ticket and proposes an implementation approach.
7. **Fix that bug** — diagnoses a bug ticket and proposes a concrete, minimal fix + tests.
8. **Generate tasks & estimations** — breaks a story into estimable **tasks**, calibrating the
   estimates against the project's historical estimate-vs-actual data.
9. **Status presentation** — generates a slide-style project status presentation from live metrics.
10. **Specification document** — generates a structured spec from the project's user stories.

Both document generators (9–10) live on the project page and save the result as an editable
**Document**.

11. **💬 Chat with AI** — a project-scoped, OpenAI-style assistant (opened from the project page).
    It loads the project's **git repo, tickets, sprint, team messages, recent code and a
    per-developer performance summary** as context, so you can just ask:
    *"Who is the fastest delivering developer?"*, *"Who has the best estimations?"*,
    *"What's the current sprint status?"* — and have it draft specs, risk docs and test plans on the spot.

Stories break down into **tasks** (small, estimable slices); a story auto-seeds one task on
creation and task completion drives its progress bar.

> **New in 2026:** server/heartbeat monitoring, richer deployments, staged ticket approval,
> per-project sprint lists with estimated/actual hours, and dedicated ceremony pages
> (standup, planning, refinement, review, retro). See **[`docs/whats_new_2026.html`](docs/whats_new_2026.html)**.

## 📜 Log viewer

Every application ships its logs to a central **Grafana Loki** store in a common JSON
shape. The in-app **Log Viewer** (`/logs`, sidebar → CI/DevOps → Log Viewer) renders them
in a readable console with **errors and exceptions highlighted**, filters by service /
level / time-range / search, and a **live "watch"** mode that tails new entries.

Find it under the sidebar **AI Agent** section (AI Reports · Recent Review Results · Recent Test
Reviews). Configure it with `OLLAMA_URL` / `OLLAMA_MODEL` (see `.env.example`). Full guide:
[`docs/ai_integration.md`](docs/ai_integration.md).

## What it does

- **Tickets & sprints** — Stories, bugs, and spikes with a full lifecycle, organized into
  sprints and milestones. Includes a Kanban board, velocity/burndown tracking, and filtering
  (mine / late / backlog / current sprint).
- **Git & CI integration** — Auto-creates Gitea branches when a ticket is assigned
  (`feature/T-X-*`), syncs pull request status, and ingests Jenkins/Gitea webhooks into CI run
  records with parsed test results.
- **CI dashboard & reports** — Build status, test coverage, security scans, deployment history,
  and estimation-accuracy reporting.
- **Meetings** — Sprint ceremonies with Jitsi video rooms, attendees, recordings, and iCalendar
  export.
- **Customer portal** — A read-only client view to file support tickets (linked to internal
  tickets), track milestones, and message the team.
- **Developer tooling** — A `devteam` CLI and a VS Code extension that talk to a token-authenticated
  `/api/v1/` API (checkout branches, update tickets, run tests, deploy).

## Tech stack

- **Backend:** Rails 8.1 (Ruby 3.4.5), SQLite in development / PostgreSQL in production
- **Infrastructure:** Solid Queue (background jobs), Solid Cache, Solid Cable (WebSockets),
  Active Storage
- **Frontend:** Hotwire (Turbo + Stimulus), Bulma / Bootstrap + SCSS, esbuild; Chartkick,
  FullCalendar, Trix
- **Auth:** Devise (with API tokens) + Pundit (role-based access control)
- **AI:** Local LLM via Ollama REST API (on-prem Mac mini), reached with Faraday
- **Deployment:** Kamal (Docker), Thruster; GitHub Actions CI (Brakeman, bundler-audit, RuboCop,
  RSpec)

## Core data model

`Project` is the central hub — it owns `Sprint`s, `Ticket`s, `Milestone`s, `CiRun`s (→
`TestResult`s), `PullRequest`s, `Deployment`s, `Meeting`s, `Document`s, and members. On the client
side, `Customer` has `CustomerTicket`s, `Installation`s, and `Message`s. An `Activity` model serves
as an audit log of events across the system.

## Integrations

Gitea (branches / PRs / webhooks), Jenkins (build triggers and results), Sentry (errors and APM),
Jitsi (video calls), SMTP (notifications), and Mattermost / Rocket.Chat (chat webhooks). Background
jobs handle branch creation, PR sync, and ticket notifications.

## Getting started

```bash
bin/setup          # install dependencies and prepare the database
bin/dev            # start the app (Rails + esbuild + Sass watchers)
bin/rails test     # or: bundle exec rspec
```

Configure external service tokens (Gitea, Jenkins, Sentry, SMTP) via environment variables — see
`.env.example` for the full list.
# comtec-devteam
