# DevTeam Hub — Stories Backlog

> **Document type:** User Story Backlog  
> **Version:** 2.0  
> **Last updated:** May 25, 2026  
> **Format:** As a [role] I want to [action] so that [benefit]

---

## Status Legend

| Symbol | Meaning |
|---|---|
| ✅ Done | Implemented and tested |
| 🔄 In Progress | Currently being worked on |
| 📋 Ready | Refined, ready to pick up |
| 🔍 Needs Refinement | Story needs more detail / investigation |
| ⏸ Blocked | Waiting on dependency |
| ❌ Won't Do | Descoped |

---

## Story Point Scale

| Points | Effort |
|---|---|
| 1 | Trivial — config change, copy fix |
| 2 | Small — simple CRUD, form, route |
| 3 | Medium — full feature, model + controller + view |
| 5 | Large — multi-model, background jobs, integration |
| 8 | XL — major integration (webhook, external service) |
| 13 | Spike / unknown — needs investigation first |

---

## Epic 1 — Authentication & User Management

| ID | Story | Points | Status | Notes |
|---|---|---|---|---|
| US-001 | As a developer I want to sign in with email and password so that my work is private to authenticated users | 2 | ✅ Done | Devise |
| US-002 | As a developer I want to stay logged in across browser sessions so that I don't re-authenticate every day | 1 | ✅ Done | Devise :rememberable |
| US-003 | As a developer I want to reset my password via email so that I can recover my account | 1 | ✅ Done | Devise :recoverable |
| US-004 | As a developer I want to update my display name, avatar, and preferred language so that my profile is personalised | 2 | ✅ Done | Profile controller + Active Storage avatar |
| US-005 | As an admin I want to view all users and change their roles so that I can control access levels | 3 | ✅ Done | Admin::UsersController |
| US-006 | As an admin I want to deactivate a user account so that a departed team member loses access without deleting their data | 2 | 🔍 Needs Refinement | Need `active` flag on users |
| US-007 | As a developer I want to be redirected to my Today page after login so that I immediately see my day's work | 1 | ✅ Done | `after_sign_in_path_for` |
| US-008 | As a system I want to throttle failed login attempts so that the application is protected against brute force | 3 | 📋 Ready | rack-attack — see Risk R10 |

---

## Epic 2 — Project Management

| ID | Story | Points | Status | Notes |
|---|---|---|---|---|
| US-010 | As a PM I want to create a project with name, description, tech stack, and Gitea repo link so that all work is centralised | 2 | ✅ Done | ProjectsController CRUD |
| US-011 | As a PM I want to archive (soft-delete) a project so that inactive projects don't clutter views | 1 | ✅ Done | `active` boolean, `.active` scope |
| US-012 | As a team member I want to see all active projects listed so that I can navigate to my project quickly | 1 | ✅ Done | projects#index |
| US-013 | As a team lead I want to see a project report page with CI stats and deployment history so that I can communicate project health to stakeholders | 3 | ✅ Done | `projects#report` |
| US-014 | As a team lead I want a CI dashboard per project showing build trends so that I can spot flaky tests early | 3 | ✅ Done | `projects#ci_dashboard` |
| US-015 | As a PM I want to create a new project from the sidebar so that project creation is always one click away | 1 | ✅ Done | "New Project" link in sidebar |
| US-016 | As a PM I want to create a new sprint directly from the project detail page so that sprint creation is contextual | 1 | ✅ Done | "New Sprint" button on project#show |

---

## Epic 3 — Sprint Management

| ID | Story | Points | Status | Notes |
|---|---|---|---|---|
| US-020 | As a PM I want to create sprints with start/end dates for a project so that we plan in iterations | 2 | ✅ Done | Sprint model + CRUD routes |
| US-021 | As a PM I want to activate a sprint (move from planning to active) so that developers know which iteration to work in | 2 | ✅ Done | Sprint status management |
| US-022 | As a PM I want to complete a sprint so that historical sprint data is preserved | 2 | ✅ Done | Sprint status management |
| US-023 | As a developer I want to see which tickets belong to the current sprint so that I focus on the right work | 2 | ✅ Done | Sprint show view + current_sprint tickets view |
| US-024 | As a PM I want to view sprint velocity (story points completed per sprint) in a report so that I can forecast future sprints | 5 | ✅ Done | `reports/sprint_velocity` |
| US-025 | As a developer I want to move tickets between sprints via drag-and-drop so that backlog grooming is fast | 8 | 🔍 Needs Refinement | Stimulus JS drag + PATCH |

---

## Epic 4 — Ticket Management

| ID | Story | Points | Status | Notes |
|---|---|---|---|---|
| US-030 | As a developer I want to create a ticket with title, description, priority, and status so that work is tracked | 2 | ✅ Done | TicketsController CRUD |
| US-031 | As a developer I want to assign a ticket to myself or a team member so that ownership is clear | 1 | ✅ Done | `assignee_id` on Ticket |
| US-032 | As a developer I want to add tags and labels to tickets so that I can group related work | 2 | ✅ Done | acts-as-taggable-on |
| US-033 | As a PM I want to see a Kanban board with tickets grouped by status so that I visualise work in progress | 5 | 📋 Ready | Needs Stimulus drag + board view |
| US-034 | As a developer I want to watch a ticket so that I receive notifications when it changes | 2 | ✅ Done | TicketWatcher model |
| US-035 | As a developer I want a Git branch auto-created in Gitea when I am assigned a ticket so that I don't create branches manually | 5 | 📋 Ready | Gitea service + background job |
| US-036 | As a developer I want to see the latest CI build status on my ticket so that I know if the branch is green | 3 | ✅ Done | `latest_ci_run_id` + status badge |
| US-037 | As a developer I want to link a pull request to a ticket so that code review and work item are connected | 2 | ✅ Done | PullRequest model + `ticket_id` FK |
| US-038 | As a PM I want to assign tickets to a milestone so that I can track progress towards a release | 2 | ✅ Done | `milestone_id` FK on Ticket |
| US-039 | As a developer I want to set story points on a ticket so that sprint capacity can be planned | 1 | ✅ Done | `story_points` column |
| US-040 | As a PM I want to block a ticket that has an unresolved dependency so that the team knows not to start it yet | 1 | ✅ Done | `blocked` status enum value |
| US-041 | As a PM I want to view all tickets across all projects with filters (status, project, assignee, owner) so that I have a global view | 3 | ✅ Done | `tickets#all` with filter form |
| US-042 | As a developer I want to access "All Tickets" from the sidebar so that cross-project ticket views are always available | 1 | ✅ Done | Sidebar tickets section |

---

## Epic 5 — CI/CD Integration

| ID | Story | Points | Status | Notes |
|---|---|---|---|---|
| US-050 | As a DevOps engineer I want Jenkins to post build results to the app via webhook so that CI data is live | 8 | ✅ Done | `WebhooksController#jenkins` |
| US-051 | As a DevOps engineer I want Gitea push events to create/update branch records so that branches are synchronised | 8 | ✅ Done | `WebhooksController#gitea` |
| US-052 | As a developer I want to see individual test results per CI run so that I know which tests failed | 3 | ✅ Done | TestResult model; `has_many :test_results` |
| US-053 | As a developer I want to click a link to the Jenkins build log from within the app so that I don't navigate Jenkins manually | 1 | ✅ Done | `log_url` column + link |
| US-054 | As a developer I want to be emailed when a CI build for my ticket fails so that I react immediately | 3 | 📋 Ready | TicketMailer#ci_failed — views missing |
| US-055 | As a team lead I want to see CI pass/fail trends per project over the last 30 days so that I monitor build health | 5 | ✅ Done | CI Dashboard + Chartkick charts |
| US-056 | As a DevOps engineer I want Gitea pull request events to create PR records in the app so that code review is linked to tickets | 5 | ✅ Done | `WebhooksController#gitea` PR handling |

---

## Epic 6 — Deployment Tracking

| ID | Story | Points | Status | Notes |
|---|---|---|---|---|
| US-060 | As a DevOps engineer I want to record a deployment with version, environment, and type so that we have a full history | 2 | ✅ Done | DeploymentsController CRUD |
| US-061 | As a DevOps engineer I want to mark a deployment as rolled back so that the history is accurate | 2 | ✅ Done | `rolled_back` status enum value |
| US-062 | As a DevOps engineer I want to track Windows installer deployments separately so that customer installs can be traced | 2 | ✅ Done | `windows_installer` deploy_type enum |
| US-063 | As a DevOps engineer I want to link a deployment to a client account so that customer-facing deployments are tracked | 2 | ✅ Done | `client_account_id` FK on Deployment |
| US-064 | As a developer I want to see my deployments from today on the Today page so that I know what went live | 2 | ✅ Done | Today page section |
| US-065 | As a PM I want a deployment summary report showing environments and frequencies so that I can communicate release cadence | 5 | ✅ Done | `reports/deployment_summary` |

---

## Epic 7 — Customer Management

| ID | Story | Points | Status | Notes |
|---|---|---|---|---|
| US-070 | As a support agent I want to add a customer with name, company, email, and contact info so that customer records are maintained | 2 | ✅ Done | CustomersController CRUD |
| US-071 | As a PM I want to search and filter customers by name, company, or email so that I find a customer quickly | 2 | ✅ Done | Customers#index with search params |
| US-072 | As a PM I want to deactivate a customer so that inactive customers are hidden from default views | 1 | ✅ Done | `active` boolean + filter toggle |
| US-073 | As a support agent I want to create a support ticket for a customer so that their issue is tracked | 2 | ✅ Done | CustomerTicketsController CRUD |
| US-074 | As a support agent I want to assign a customer ticket to a team member so that ownership is clear | 1 | ✅ Done | `assigned_to_id` FK |
| US-075 | As a support agent I want to resolve a customer ticket with a single click so that resolution time is recorded | 2 | ✅ Done | `#resolve!` + `patch :resolve` route |
| US-076 | As a team lead I want to link a customer ticket to an internal development ticket so that root cause is traceable | 2 | ✅ Done | `#link_to_internal!` + `patch :link_ticket` |
| US-077 | As a support agent I want to filter customer tickets by status so that I focus on open issues | 1 | ✅ Done | Tabs on CustomerTickets#index |
| US-078 | As a support agent I want to set priority (low/medium/high/critical) on a customer ticket so that urgent issues are visible | 1 | ✅ Done | Priority enum with prefix |
| US-079 | As a PM I want role-based access control on customer data so that only authorised staff can edit customer records | 5 | 📋 Ready | Pundit policies needed |

---

## Epic 8 — Installation Tracking

| ID | Story | Points | Status | Notes |
|---|---|---|---|---|
| US-080 | As a support engineer I want to record which software version is installed at a customer site so that I know the exact version before troubleshooting | 2 | ✅ Done | InstallationsController CRUD |
| US-081 | As a support engineer I want previous active installations to be automatically marked outdated when I add a new version so that the latest version is always clear | 3 | ✅ Done | `after_create :mark_previous_as_outdated` |
| US-082 | As a support engineer I want to filter installations by environment (production/staging/uat) so that I find the right instance | 1 | ✅ Done | Environment filter buttons |
| US-083 | As a DevOps engineer I want to link an installation to the deployment that produced it so that I can trace build → install | 2 | ✅ Done | `deployment_id` FK |
| US-084 | As a PM I want to see how many active installations a customer has from the customer profile page so that I understand their footprint | 1 | ✅ Done | Installations count on Customers#show |
| US-085 | As a support engineer I want to filter installations by status (active/outdated/failed) so that I spot problems quickly | 1 | ✅ Done | Status filter |

---

## Epic 9 — Meeting Management

| ID | Story | Points | Status | Notes |
|---|---|---|---|---|
| US-090 | As a team lead I want to schedule a meeting with type, agenda, and attendees so that the team has shared calendar entries | 3 | ✅ Done | MeetingsController CRUD |
| US-091 | As a team member I want to join a meeting via a Jitsi link embedded in the app so that I don't search for meeting links | 2 | ✅ Done | `jitsi_url` method + Join button |
| US-092 | As a team lead I want to end a meeting and record notes so that decisions are documented | 2 | ✅ Done | `post :end_meeting` route |
| US-093 | As a developer I want to export a meeting to my calendar as an .ics file so that my calendar is synchronised | 2 | ✅ Done | `get :ical` + iCalendar gem |
| US-094 | As a developer I want to see today's meetings on my Today page so that I don't miss any | 2 | ✅ Done | Today page meetings section |
| US-095 | As a team member I want to mark my attendance at a meeting so that attendance is recorded | 1 | 📋 Ready | `attended` boolean on MeetingAttendee |

---

## Epic 10 — Documentation

| ID | Story | Points | Status | Notes |
|---|---|---|---|---|
| US-100 | As a developer I want to create project documentation with Markdown content so that knowledge is shared | 2 | ✅ Done | DocumentsController CRUD + Redcarpet |
| US-101 | As a developer I want to categorise a document by type (spec, architecture, runbook, etc.) so that docs are organised | 1 | ✅ Done | `doc_type` enum |
| US-102 | As a developer I want to tag a document so that related docs are discoverable | 1 | ✅ Done | `acts_as_taggable_on :tags` |
| US-103 | As a PM I want to attach a PDF or image to a document so that binary files are stored alongside text docs | 2 | ✅ Done | Active Storage attachment |
| US-104 | As a developer I want to comment on a document so that team discussion is captured in-context | 2 | ✅ Done | Polymorphic comments |
| US-105 | As a developer I want to see documents updated today on my Today page so that I notice new knowledge | 1 | ✅ Done | Today page docs section |
| US-106 | As a PM I want to version a document (version_number field) so that I can track document revisions | 1 | ✅ Done | `version_number` column |
| US-107 | As a developer I want to preview Markdown content in a document so that I see the rendered output | 1 | ✅ Done | Markdown rendering with Redcarpet |
| US-108 | As a developer I want to browse all documents across projects from the sidebar so that cross-project docs are accessible | 1 | ✅ Done | `all_documents#index` route |

---

## Epic 11 — Notifications

| ID | Story | Points | Status | Notes |
|---|---|---|---|---|
| US-110 | As a developer I want to see a notification bell in the navbar with an unread count so that I notice events quickly | 2 | ✅ Done | Notifications + unread count |
| US-111 | As a developer I want to mark a notification as read so that my unread count is accurate | 1 | ✅ Done | `patch :mark_read` route |
| US-112 | As a developer I want to mark all notifications as read so that I can clear the badge at once | 1 | ✅ Done | `post :mark_all_read` |
| US-113 | As a developer I want to receive an email when a ticket is assigned to me so that I am alerted without checking the app | 3 | 📋 Ready | TicketMailer#assigned |
| US-114 | As a developer I want to receive an email when a watched ticket changes status so that I stay informed | 3 | 📋 Ready | TicketMailer#status_changed |
| US-115 | As a developer I want to receive an email when a CI build for my ticket fails so that I react immediately | 3 | 📋 Ready | TicketMailer#ci_failed |

---

## Epic 12 — Today Page (Developer Dashboard)

| ID | Story | Points | Status | Notes |
|---|---|---|---|---|
| US-120 | As a developer I want to be taken to a personalised Today page after login so that I see my day at a glance | 2 | ✅ Done | `today#index` |
| US-121 | As a developer I want to see my active tickets on the Today page so that I know what to work on | 2 | ✅ Done | Active Tickets section |
| US-122 | As a developer I want to see today's meetings with Jitsi join links so that I never miss a meeting | 2 | ✅ Done | Meetings section |
| US-123 | As a developer I want to see my CI runs from today with pass/fail counts so that I monitor build health | 2 | ✅ Done | CI Runs section |
| US-124 | As a developer I want to see failing builds highlighted with log links so that I fix them immediately | 2 | ✅ Done | Failing builds alert |
| US-125 | As a developer I want to see documents updated today so that I notice knowledge changes | 1 | ✅ Done | Docs section |
| US-126 | As a developer I want to see milestones due today or overdue so that deadline risk is visible | 2 | ✅ Done | Milestones section |
| US-127 | As a developer I want quick CI links (Jenkins + Gitea) so that I access CI without bookmarks | 2 | ✅ Done | CI quick links |
| US-128 | As a developer I want my deployments from today shown so that I know what went live | 1 | ✅ Done | Deployments section |

---

## Epic 13 — Internationalisation

| ID | Story | Points | Status | Notes |
|---|---|---|---|---|
| US-130 | As a Hebrew-speaking developer I want to switch the UI to Hebrew so that I use the app in my native language | 3 | ✅ Done | `he.yml` + language switcher |
| US-131 | As a Hebrew-speaking developer I want the UI to render right-to-left when Hebrew is selected so that Hebrew text is readable | 2 | ✅ Done | `dir="rtl"` + Bootstrap RTL |
| US-132 | As a developer I want my language preference saved on my profile so that I don't switch language on every login | 1 | ✅ Done | `preferred_language` on User |
| US-133 | As a developer I want all email subjects and bodies to be in my preferred language so that communications are localised | 3 | 📋 Ready | Mailer localisation |

---

## Epic 14 — Admin & Reporting

| ID | Story | Points | Status | Notes |
|---|---|---|---|---|
| US-140 | As an admin I want a user management panel to view, edit roles, and deactivate users | 3 | ✅ Done | Admin::UsersController |
| US-141 | As an admin I want a client accounts panel to manage CRM-style account records | 2 | ✅ Done | Admin::ClientAccountsController |
| US-142 | As a PM I want a CI summary report showing builds, pass rate, and average duration so that I report on quality | 5 | ✅ Done | `reports/ci_summary` |
| US-143 | As a PM I want a deployment summary report showing deploy frequency per environment so that I report on release cadence | 5 | ✅ Done | `reports/deployment_summary` |
| US-144 | As a QA lead I want a test coverage report showing pass rate trends so that I measure test suite health | 5 | ✅ Done | `reports/test_coverage` |
| US-145 | As a PM I want sprint velocity charts so that I measure team throughput | 5 | ✅ Done | `reports/sprint_velocity` |
| US-146 | As a PM I want estimation accuracy reports so that I improve future estimates | 5 | ✅ Done | `reports/estimation_accuracy` |

---

## Epic 15 — UI Polish & UX

| ID | Story | Points | Status | Notes |
|---|---|---|---|---|
| US-150 | As a user I want table action buttons in dropdown menus (kebab ⋮) so that tables are clean and uncluttered | 3 | ✅ Done | `actions_dropdown` helper across all tables |
| US-151 | As a user I want dark table headers with white text so that tables are visually distinct | 1 | ✅ Done | SCSS `thead th` styling |
| US-152 | As a user I want dropdown menus to have proper white backgrounds so that text is readable | 1 | ✅ Done | Bootstrap CSS override |
| US-153 | As a user I want horizontally scrollable tables on mobile so that data doesn't overflow | 1 | ✅ Done | `table-responsive` wrappers |
| US-154 | As a user I want user avatars displayed in the sidebar and team section so that the interface feels personal | 2 | ✅ Done | Active Storage avatars + `user_avatar` helper |

---

## Epic 16 — Customer Portal

| ID | Story | Points | Status | Notes |
|---|---|---|---|---|
| US-160 | As a customer I want a dedicated portal login so that I access my project information securely | 3 | ✅ Done | CustomerUser Devise + `/portal` |
| US-161 | As a customer I want to view and create support tickets so that I can report issues | 3 | ✅ Done | CustomerPortal::TicketsController |
| US-162 | As a customer I want to send messages to the dev team so that I can communicate without email | 2 | ✅ Done | CustomerPortal::MessagesController |
| US-163 | As a customer I want to view project milestones so that I see progress towards releases | 2 | ✅ Done | CustomerPortal::MilestonesController |
| US-164 | As a customer I want to view public documents so that I can read specs and documentation | 2 | ✅ Done | CustomerPortal::DocumentsController |

---

## Epic 17 — CLI & VS Code Extension

| ID | Story | Points | Status | Notes |
|---|---|---|---|---|
| US-170 | As a developer I want a CLI tool (`dt`) to manage tickets from the terminal | 5 | ✅ Done | `cli/dt` + API v1 |
| US-171 | As a developer I want to query centralised logs from the CLI | 3 | ✅ Done | `dt logs` + Loki proxy |
| US-172 | As a developer I want a VS Code extension for ticket management | 5 | ✅ Done | `vscode-extension/` |

---

## Backlog Summary

| Epic | Total | ✅ Done | 📋 Ready | 🔍 Refinement |
|---|---|---|---|---|
| 1 — Auth & Users | 8 | 6 | 1 | 1 |
| 2 — Projects | 7 | 7 | 0 | 0 |
| 3 — Sprints | 6 | 5 | 0 | 1 |
| 4 — Tickets | 14 | 12 | 1 | 0 |
| 5 — CI/CD | 7 | 6 | 1 | 0 |
| 6 — Deployments | 6 | 6 | 0 | 0 |
| 7 — Customers | 10 | 9 | 1 | 0 |
| 8 — Installations | 6 | 6 | 0 | 0 |
| 9 — Meetings | 6 | 5 | 1 | 0 |
| 10 — Documentation | 9 | 9 | 0 | 0 |
| 11 — Notifications | 6 | 3 | 3 | 0 |
| 12 — Today Page | 9 | 9 | 0 | 0 |
| 13 — i18n | 4 | 3 | 1 | 0 |
| 14 — Admin & Reports | 7 | 7 | 0 | 0 |
| 15 — UI Polish | 5 | 5 | 0 | 0 |
| 16 — Customer Portal | 5 | 5 | 0 | 0 |
| 17 — CLI & Extension | 3 | 3 | 0 | 0 |
| **Total** | **122** | **106** | **9** | **2** |

**Completion rate: 87%** (106 of 122 stories done)
