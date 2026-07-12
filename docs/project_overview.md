# DevTeam Hub — Project Documentation

> **Version:** 2.1  
> **Last updated:** June 5, 2026  
> **Stack:** Ruby on Rails 8.1.3 · SQLite3 · Bootstrap 5 · Stimulus JS · Solid Queue · Ollama (local LLM)

---

## 1. What Is DevTeam Hub?

DevTeam Hub is an internal developer-team management dashboard built with Ruby on Rails 8. It centralises every aspect of a software-development team's day-to-day work into a single web application:

- **Project & Sprint tracking** — manage projects, iterations, and milestones with quick-create actions
- **Ticket (issue) management** — comprehensive work items with CI status badges, cross-project views, and advanced filtering
- **Customer support** — customer accounts, support tickets, and software installation records
- **CI/CD integration** — real-time Jenkins build results and Gitea repository events via webhooks
- **Deployment tracking** — web, Windows installer, Windows service, and Docker deploys
- **Meeting management** — schedule and join Jitsi video meetings from within the app
- **Documentation** — project-scoped knowledge base with Markdown rendering and document templates
- **Pull Request tracking** — PR records synced from Gitea with CI test result integration
- **Notifications** — in-app and email notifications for ticket assignments and CI failures
- **Chat rooms** — Slack-style team messaging channels with rich entity references
- **Customer Portal** — isolated, secure portal for customers to view project status, submit tickets, and communicate
- **Reporting** — CI summary, deployment summary, test coverage, sprint velocity, and estimation accuracy reports
- **Calendar** — full calendar view with meetings and sprint milestones
- **Internationalisation** — full English and Hebrew (RTL) support
- **Today Page** — personalised landing page for each developer showing their day at a glance
- **Admin panel** — user management and client account administration
- **CLI & VS Code extension** — `devteam` / `dt` command-line tool and IDE integration via REST API
- **AI Agent (local LLM)** — on-prem Ollama model for ticket readiness checks, code review (Go/Ruby/C#/Node), cucumber test review, estimation analytics, live sprint analysis, solution suggestions, **bug fixing**, and **story → task breakdown with calibrated estimates** — code never leaves the LAN (see §10)
- **Tasks** — stories break into estimable tasks; task completion drives story progress (see §10)
- **Log Viewer** — readable, highlighted view of the central Loki logs with service/level/search filters and a live "watch" tail (`/logs`)
- **Server monitoring** — remote machines post OS telemetry to a heartbeat API; the **Servers** page shows live CPU/memory/disk health and historical charts per machine (`/servers`)
- **Chat with AI** — project-scoped assistant that answers natural-language questions about delivery, estimates and sprint status (see §10)

The application targets small-to-medium software teams (5–30 developers) who want an on-premise, self-hosted alternative to Jira + Confluence + Freshdesk combined.

---

## 2. Technology Stack

| Layer | Technology |
|---|---|
| Framework | Ruby on Rails 8.1.3 |
| Language | Ruby 3.4.5 |
| Database | SQLite3 (~> 2.0) |
| Web server | Puma |
| Background jobs | Solid Queue |
| Cache | Solid Cache |
| WebSockets | Solid Cable |
| Frontend CSS | Bootstrap 5 + Custom SCSS |
| Frontend JS | Stimulus + Turbo (Hotwire) |
| Asset pipeline | Propshaft + jsbundling-rails + cssbundling-rails |
| Authentication | Devise (dual model: User + CustomerUser) |
| Authorisation | Pundit |
| HTTP client | Faraday |
| Pagination | Kaminari |
| Charts | Chartkick + Groupdate |
| Search | Ransack |
| Notifications | Noticed ~> 2.0 |
| Error tracking | Sentry (sentry-ruby + sentry-rails) |
| Logging | Lograge (JSON format) → Grafana Loki |
| Markdown | Redcarpet |
| Calendar export | iCalendar |
| Tagging | acts-as-taggable-on |
| PDF generation | Prawn + prawn-table |
| File uploads | Active Storage (local disk) |
| Testing (unit) | RSpec + FactoryBot + Shoulda-matchers + Faker |
| Testing (BDD) | Cucumber-rails + Capybara |
| Deployment tooling | Kamal + Thruster |
| Containerisation | Docker + docker-compose |

---

## 3. Application Architecture

```
┌─────────────────────────────────────────────────┐
│                  Browser / PWA                  │
│         Turbo frames + Stimulus JS              │
└─────────────┬───────────────────────────────────┘
              │ HTTP / WebSocket
┌─────────────▼───────────────────────────────────┐
│              Puma (Rails 8 app)                 │
│  ┌─────────┐ ┌──────────────┐ ┌──────────────┐ │
│  │ Routes  │ │  Controllers │ │    Views     │ │
│  └────┬────┘ └──────┬───────┘ └──────┬───────┘ │
│       │             │                │          │
│  ┌────▼─────────────▼────────────────▼───────┐  │
│  │              Active Record Models         │  │
│  └────────────────────┬──────────────────────┘  │
│                       │                         │
│          ┌────────────▼──────────┐              │
│          │     SQLite3 DB        │              │
│          └───────────────────────┘              │
│                                                 │
│  ┌──────────────────────────────────────────┐   │
│  │  Solid Queue (background jobs)           │   │
│  │  · TicketMailer jobs                     │   │
│  │  · Notification dispatch                 │   │
│  │  · Gitea branch creation                 │   │
│  └──────────────────────────────────────────┘   │
│                                                 │
│  ┌──────────────────────────────────────────┐   │
│  │  Customer Portal (/portal)               │   │
│  │  · Isolated Devise model (CustomerUser)  │   │
│  │  · Separate base controller & layout     │   │
│  │  · Tickets, Messages, Milestones, Docs   │   │
│  └──────────────────────────────────────────┘   │
│                                                 │
│  ┌──────────────────────────────────────────┐   │
│  │  REST API (api/v1/*)                     │   │
│  │  · CLI & VS Code Extension backend       │   │
│  │  · Tickets, CI Runs, Deployments, PRs    │   │
│  │  · Loki log proxy                        │   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
              │                   │
     ┌────────▼───┐      ┌────────▼───────┐
     │  Jenkins   │      │   Gitea server │
     │  (webhooks)│      │  (webhooks)    │
     └────────────┘      └────────────────┘
              │
     ┌────────▼───────────────────────────┐
     │  SonarQube + Ollama AI             │
     │  (code review pipeline)            │
     └───────────────────────────────────┘
              │
     ┌────────▼───────────────────────────┐
     │  Grafana Loki + Promtail           │
     │  (centralised logging)             │
     └───────────────────────────────────┘
```

**Key design choices:**

- Shallow-nested routes keep URLs short while maintaining resource context
- Polymorphic `comments` and `notifications` reduce table count
- `serialize :params, coder: JSON` on `Notification#params` since SQLite has no native JSON column
- Enum integers stored in DB for efficiency; all enums have named scopes
- Dual Devise authentication models for team (User) and customer (CustomerUser) isolation
- Kebab dropdown menus (`⋮`) for table row actions to reduce visual clutter
- Bootstrap 5 with RTL support via `dir="rtl"` attribute

---

## 4. UI Features & Navigation

### 4.1 Sidebar Navigation

The application uses a Slack-style sidebar with the following sections:

| Section | Items |
|---|---|
| **Navigation** | Today, Dashboard, Meetings, Calendar, Notifications, Documents, Customers, Active Sprint |
| **Tickets** | All Tickets (with filters), My Tickets, Late Tickets, Backlog, Current Sprint |
| **Sprints** | Per-project sprint links |
| **Projects** | New Project button, project list with CI status dots (green/red/amber) |
| **Reports** | CI Summary, Deployments, Test Coverage, Sprint Velocity, Estimation Accuracy |
| **Admin** | Users, Client Accounts (admin-only) |
| **Team** | Team member list with avatars, quick meeting invite |
| **User** | Avatar, name, profile edit, language toggle, sign out |

### 4.2 Action Dropdown Menus

All data tables use kebab (`⋮`) dropdown menus for row actions (edit, delete, view, etc.) instead of inline buttons. This reduces visual clutter and provides a consistent interaction pattern across the application. The menus are RTL-aware and automatically adjust alignment for Hebrew layouts.

### 4.3 Cross-Project Ticket Views

Tickets can be viewed across all projects with the following cross-project views:

| View | Path | Description |
|---|---|---|
| All Tickets | `/tickets` | All tickets with filters for status, project, assignee, and owner |
| My Tickets | `/tickets/mine` | Tickets assigned to the current user |
| Late Tickets | `/tickets/late` | Overdue tickets |
| Backlog | `/tickets/backlog` | Tickets in backlog status |
| Current Sprint | `/tickets/current_sprint` | Tickets in the active sprint |

---

## 5. Models & Database

The application has 22+ database tables. Key models include:

| Model | Description |
|---|---|
| **User** | Team members with roles (developer, team_lead, project_manager, admin, qa) |
| **Project** | Top-level container with CI status, Gitea repo link, member management |
| **Ticket** | Work items with status, priority, assignee, sprint, milestone, CI, PR linking |
| **Sprint** | Iteration containers (planning → active → completed/cancelled) |
| **Milestone** | Release gates linked to projects and tickets |
| **CiRun** | Jenkins build records with status, duration, log URL |
| **TestResult** | Individual test case outcomes per CI run |
| **Deployment** | Deploy events (web/installer/service/Docker) per environment |
| **Document** | Markdown articles with templates, attachments, and tagging |
| **Meeting** | Scheduled meetings with Jitsi, iCal export, attendance |
| **Customer** | External customer accounts with soft-delete |
| **CustomerTicket** | Support tickets with resolution tracking and internal linking |
| **Installation** | Software version tracking at customer sites with auto-outdating |
| **PullRequest** | PR records from Gitea with CI test results |
| **Branch** | Git branch records synced from Gitea |
| **Notification** | Polymorphic in-app notifications (STI support) |
| **Comment** | Polymorphic comments on tickets, documents, meetings, PRs |
| **ChatRoom / ChatMessage** | Slack-style messaging channels |
| **ClientAccount** | CRM-style account records |
| **CustomerUser** | Separate Devise model for customer portal authentication |

---

## 6. Key URL Routes

| Path | Controller#Action | Notes |
|---|---|---|
| `/` | `dashboard#index` | Root, requires auth |
| `/today` | `today#index` | Developer's personalised day view |
| `/dashboard` | `dashboard#index` | Team-wide dashboard |
| `/calendar` | `calendar#index` | Full calendar view |
| `/projects` | `projects#index` | Project list |
| `/projects/new` | `projects#new` | Create new project |
| `/projects/:id` | `projects#show` | Project detail with members, sprints, stats |
| `/projects/:id/tickets` | `tickets#index` | Tickets per project |
| `/projects/:id/ci_dashboard` | `projects#ci_dashboard` | CI stats page |
| `/projects/:id/ci_runs` | `ci_runs#index` | CI runs per project |
| `/projects/:id/deployments` | `deployments#index` | Deployments per project |
| `/projects/:id/sprints` | `sprints#index` | Sprints per project |
| `/projects/:id/sprints/new` | `sprints#new` | Create new sprint |
| `/projects/:id/pull_requests` | `pull_requests#index` | PRs per project |
| `/projects/:id/documents` | `documents#index` | Documents per project |
| `/tickets` | `tickets#all` | All tickets with filters |
| `/tickets/mine` | `tickets#mine` | My assigned tickets |
| `/tickets/late` | `tickets#late` | Overdue tickets |
| `/tickets/backlog` | `tickets#backlog_list` | Backlog tickets |
| `/tickets/current_sprint` | `tickets#current_sprint` | Current sprint tickets |
| `/tickets/:id` | `tickets#show` | Ticket detail |
| `/documents` | `all_documents#index` | All documents |
| `/documents/:id` | `documents#show` | Document with Markdown preview |
| `/meetings` | `meetings#index` | Meeting list |
| `/meetings/:id` | `meetings#show` | Meeting with Jitsi join |
| `/notifications` | `notifications#index` | In-app notifications |
| `/customers` | `customers#index` | Customer list |
| `/customers/:id` | `customers#show` | Customer detail |
| `/customers/:id/customer_tickets` | `customer_tickets#index` | Support tickets |
| `/customers/:id/installations` | `installations#index` | Installations |
| `/reports/*` | reports controllers | CI, deployments, test coverage, velocity, estimation |
| `/admin/users` | `admin/users#index` | User management |
| `/admin/client_accounts` | `admin/client_accounts#index` | Client accounts |
| `/profile/edit` | `profile#edit` | User profile |
| `/portal` | `customer_portal/dashboard#index` | Customer portal |
| `/webhooks/gitea` | `webhooks#gitea` | Gitea webhook |
| `/webhooks/jenkins` | `webhooks#jenkins` | Jenkins webhook |
| `/api/v1/*` | API controllers | REST API for CLI & extension |

---

## 7. Authentication & Authorisation

### Devise (Dual Model)

**Team (User):** database_authenticatable, registerable, recoverable, rememberable, validatable. Post-login redirect → `today_path`.

**Customers (CustomerUser):** Separate Devise under `/portal`. Isolated base controller, separate layout, scoped data access.

### Pundit

- Policies on all resources
- Role hierarchy: developer < team_lead < project_manager < admin / qa
- `NotAuthorizedError` → redirect with flash

---

## 8. Webhooks & Integrations

| Endpoint | Source | Verification |
|---|---|---|
| `POST /webhooks/gitea` | Gitea server | HMAC-SHA256 |
| `POST /webhooks/jenkins` | Jenkins | Secret token header |
| `POST /webhooks/exception` | Exception reporting | — |

Events: Gitea push → Branch, pull_request → PullRequest, issues → Ticket. Jenkins build → CiRun + notifications.

---

## 9. CLI & VS Code Extension

REST API at `/api/v1/` powers the `devteam` / `dt` CLI and VS Code extension:

- **Tickets:** list, show, create, update
- **CI Runs:** list, show, create, with test results
- **Deployments:** list, show, create, update
- **Pull Requests:** list, show, create
- **Logs:** query Loki, list services, push logs, stats
- **Projects:** list, show
- **Auth:** token management

---

## 10. AI Agent — Local LLM Integration

DevTeam Hub embeds a **local Large Language Model** into the team's workflow and
CI process. The model runs **on-premises** on a dedicated **Mac mini** via
[Ollama](https://ollama.com); DevTeam Hub calls it over a plain HTTP REST API on
the LAN (`Ai::OllamaClient`, built on Faraday — no extra gem). **No code, ticket
text, or customer data ever leaves the local network.**

Every run is stored as an `AiReview` record (kind, verdict `pass`/`needs_work`/`fail`,
0–100 score, full Markdown body, model, duration) so results are auditable and
surface in the UI.

**Services exposed to the LLM machine:**

| # | Service | What it does | Trigger |
|---|---------|--------------|---------|
| 1 | **Ticket readiness** | Verifies story-telling / Definition of Ready; **auto-reassigns poorly-written tickets back to the owner** | Ticket page · "✅ Check readiness" |
| 2 | **Code review** | Reviews a diff for bugs, security, lint & best practice across **Go / Ruby / C# / Node** | Ticket page · "🔍 Code review" |
| 3 | **Cucumber test review** | Reviews `.feature` files; suggests changes, optimizations and **missing scenarios** | Ticket page · "🧪 Test review" |
| 4 | **Estimation accuracy** | Estimated vs actual delivery time; bias, per-developer patterns, coaching | Sprint page · "📊 AI Estimation" |
| 5 | **Sprint analysis** | Live sprint-health read (on-track? risks? next step?) | Sprint page · live panel |
| 6 | **Solution suggestion** | Reads a ticket and proposes an implementation approach | Ticket page · "💡 Suggest solution" |
| 7 | **Fix that bug** | Diagnoses a bug ticket and proposes a concrete, minimal fix + tests | Ticket page · "🐛 Fix that bug" |
| 8 | **Generate tasks & estimations** | Breaks a story into estimable **Tasks**, calibrating estimates on the project's history | Ticket page · "🧩 Generate tasks & estimations" |
| 9 | **Status presentation** | Generates a slide-style project status presentation from live metrics | Project page · "🤖 Status Presentation" |
| 10 | **Specification document** | Generates a structured spec from the project's user stories | Project page · "🤖 Generate Spec" |
| 11 | **Chat with AI** | Project-scoped, context-aware assistant (repo + tickets + sprint + team performance). Answers "who delivers fastest / estimates best / sprint status?" and drafts docs | Project page · "💬 Chat with AI" |

**Tasks:** every story owns a list of **Tasks** (estimable slices). A story
auto-seeds one task on creation; task completion drives the story's progress bar.

**UI:** the sidebar **AI Agent** section links to **AI Reports** (`/tools/ai`),
**Recent Review Results**, and **Recent Test Reviews**. The sprint page shows the
analysis **live** via a lazy Turbo Frame.

**Config:** `OLLAMA_URL`, `OLLAMA_MODEL`, `OLLAMA_TIMEOUT` (see `.env.example`).

> Full details, setup, CI usage and the roadmap of additional services are in
> [`docs/ai_integration.md`](ai_integration.md).

---

## 11. On-Premises Tools

| Tool | Purpose |
|---|---|
| **Gitea** | Git server — repos, branches, PRs, code review |
| **Jenkins** | CI/CD — builds, tests, deployments |
| **Jitsi** | Video conferencing — meetings, stand-ups |
| **SonarQube** | Static code analysis — Quality Gates, OWASP SAST |
| **Ollama** | AI code review — Qwen2.5-Coder 32B, local |
| **Grafana Loki** | Centralised logging — JSON, correlation IDs |
| **Grafana** | Log dashboards and alerting |
| **Sentry** | Error tracking and monitoring |

---

## 12. Internationalisation

- **Locales:** English (`en`) and Hebrew (`he`) with full RTL support
- **User preference:** `preferred_language` on User model
- **Detection order:** `params[:locale]` → `current_user.preferred_language` → default
- **Language toggle:** available in sidebar footer

---

## 13. Screenshots

Application screenshots are available in both languages:

- **English (LTR):** `docs/screenshots/en/`
- **Hebrew (RTL):** `docs/screenshots/he/`

| # | Page | File |
|---|---|---|
| 01 | Today (personal dashboard) | `01_today.png` |
| 02 | Dashboard (team overview) | `02_dashboard.png` |
| 03 | All Tickets (with filters) | `03_all_tickets.png` |
| 04 | My Tickets | `04_my_tickets.png` |
| 05 | Late Tickets | `05_late_tickets.png` |
| 06 | Backlog | `06_backlog.png` |
| 07 | Current Sprint | `07_current_sprint.png` |
| 08 | Ticket Detail | `08_ticket_detail.png` |
| 09 | Projects List | `09_projects.png` |
| 10 | Project Detail | `10_project_detail.png` |
| 11 | Project Tickets | `11_project_tickets.png` |
| 12 | Project CI Runs | `12_project_ci_runs.png` |
| 13 | Project Deployments | `13_project_deployments.png` |
| 14 | Project Sprints | `14_project_sprints.png` |
| 15 | Project Pull Requests | `15_project_pull_requests.png` |
| 16 | Project Documents | `16_project_documents.png` |
| 17 | CI Dashboard | `17_ci_dashboard.png` |
| 18 | Meetings | `18_meetings.png` |
| 19 | Meeting Detail | `19_meeting_detail.png` |
| 20 | Calendar | `20_calendar.png` |
| 21 | Notifications | `21_notifications.png` |
| 22 | Documents (all) | `22_documents.png` |
| 23 | Document Detail | `23_document_detail.png` |
| 24 | Customers | `24_customers.png` |
| 25 | Customer Detail | `25_customer_detail.png` |
| 26 | Customer Tickets | `26_customer_tickets.png` |
| 27 | Installations | `27_installations.png` |
| 28 | CI Run Detail | `28_ci_run_detail.png` |
| 29 | Deployment Detail | `29_deployment_detail.png` |
| 30 | Sprint Detail | `30_sprint_detail.png` |
| 31 | Pull Request Detail | `31_pull_request_detail.png` |
| 32 | Report: CI Summary | `32_report_ci_summary.png` |
| 33 | Report: Deployments | `33_report_deployments.png` |
| 34 | Report: Test Coverage | `34_report_test_coverage.png` |
| 35 | Report: Sprint Velocity | `35_report_velocity.png` |
| 36 | Report: Estimation Accuracy | `36_report_estimation.png` |
| 37 | Admin: Users | `37_admin_users.png` |
| 38 | Admin: Client Accounts | `38_admin_clients.png` |
| 39 | Profile Edit | `39_profile_edit.png` |
