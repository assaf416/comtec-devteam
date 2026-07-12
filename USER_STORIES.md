# DevTeam Hub — User Story Breakdown

## Epic 1: Project & Sprint Management

### E1-US01 — Create and manage projects

**As a** Project Manager  
**I want to** create projects with a name, tech stack, and Gitea repository link  
**So that** all team activity (tickets, CI, deployments, docs) is organised under a single entity  
**Acceptance Criteria:**

- Project has name, description, tech_stack, repo_url, active flag
- Inactive projects are hidden from default views
- Admin and PM can create/edit/archive; developers read-only

### E1-US02 — Manage sprints

**As a** Team Lead  
**I want to** create sprints with start/end dates and assign tickets to them  
**So that** we can plan iterations and measure velocity  
**Acceptance Criteria:**

- Sprint has status (planning → active → completed)
- Only one sprint can be active per project at a time
- Tickets show which sprint they belong to

### E1-US03 — Track milestones

**As a** Project Manager  
**I want to** define milestones with a due date and link tickets to them  
**So that** I can track progress towards release goals  
**Acceptance Criteria:**

- Milestone has title, description, due_date
- Tickets can be assigned to a milestone
- Dashboard shows overdue milestones

---

## Epic 2: Ticket Management

### E2-US01 — Create and triage tickets

**As a** Developer or QA  
**I want to** create tickets with title, description, priority, and status  
**So that** the team can track work items  
**Acceptance Criteria:**

- Status lifecycle: Backlog → Open → In Progress → In Review → Testing → Done → Closed
- Priority: Low / Medium / High / Critical
- Tags and labels support via acts-as-taggable-on

### E2-US02 — Kanban board view

**As a** Team member  
**I want to** see all tickets in a Kanban board organised by status column  
**So that** I can visualise work in progress at a glance  
**Acceptance Criteria:**

- 8 columns match ticket statuses
- Cards show priority colour, assignee avatar, CI status badge, branch name
- Drag or click to move tickets between columns (Stimulus JS)

### E2-US03 — Auto-create Git branch on ticket assignment

**As a** Developer  
**I want to** have a Git branch automatically created when I am assigned a ticket  
**So that** I don't need to manually create branches  
**Acceptance Criteria:**

- Branch named `feature/<ticket-id>-<slug>` created in Gitea via API
- Branch record saved to DB
- `ticket.branch_name` updated
- Job runs as background job (Solid Queue)

### E2-US04 — CI status on tickets

**As a** Developer  
**I want to** see the CI status of the latest build for a ticket's branch  
**So that** I know if my changes are green without leaving the ticket view  
**Acceptance Criteria:**

- Ticket show page displays latest CI run status with colour badge
- CI run table shows build number, duration, pass/fail counts
- Failed CI triggers email notification to assignee

### E2-US05 — Watch tickets for notifications

**As a** Team member  
**I want to** watch a ticket to receive notifications about status changes  
**So that** I stay informed without being the assignee  
**Acceptance Criteria:**

- Add/remove watch from ticket detail page
- Watchers receive in-app and email notifications on status change

---

## Epic 3: Customer Management

### E3-US01 — Manage customer accounts

**As a** Project Manager  
**I want to** add and manage customer records (name, company, contact info)  
**So that** all customer-facing activity is tied to a customer entity  
**Acceptance Criteria:**

- Customer has name, company, email, phone, contact_person, active flag
- Email must be unique across customers
- Search and filter by name/company; filter active-only toggle

### E3-US02 — Customer support tickets

**As a** Support Agent  
**I want to** log support tickets on behalf of a customer  
**So that** we can track issues reported by that customer  
**Acceptance Criteria:**

- Customer ticket has title, body/message, priority, status
- Status lifecycle: Open → In Progress → Waiting for Customer → Resolved → Closed
- Support agent can assign ticket to a team member
- Ticket can be linked to an internal development ticket for root-cause tracking

### E3-US03 — Resolve and close customer tickets

**As a** Support Agent  
**I want to** mark a customer ticket as resolved  
**So that** we track resolution time and close the feedback loop  
**Acceptance Criteria:**

- "Mark Resolved" button sets `resolved_at` timestamp
- Resolved tickets show resolution date
- Closed tickets are excluded from open ticket count

### E3-US04 — Link customer ticket to internal ticket

**As a** Team Lead  
**I want to** link a customer ticket to an internal development ticket  
**So that** I can trace which code change resolves the customer's issue  
**Acceptance Criteria:**

- Dropdown of all internal tickets on customer ticket detail page
- Once linked, internal ticket is shown with hyperlink
- Internal ticket detail shows count of linked customer tickets

---

## Epic 4: Installation Tracking

### E4-US01 — Track installed software per customer

**As a** Support Engineer  
**I want to** record which software version is installed at each customer site  
**So that** I know the exact version in production before troubleshooting  
**Acceptance Criteria:**

- Installation has: software_name, version, environment, installed_at, status, notes
- Status: Active / Pending / Outdated / Decommissioned / Failed
- Environments: production, staging, uat, development

### E4-US02 — Auto-mark old versions as outdated

**As a** Support Engineer  
**I want to** have previous active installations automatically marked outdated when a new version is tracked  
**So that** the latest version is always clearly identified  
**Acceptance Criteria:**

- When a new Active installation is created for the same customer + software, all prior Active ones become Outdated
- Outdated rows are highlighted in the installations table

### E4-US03 — Link installation to deployment record

**As a** DevOps Engineer  
**I want to** link a customer installation to the deployment record that produced it  
**So that** I can trace exactly which CI run, branch, and commit is running at the customer site  
**Acceptance Criteria:**

- Installation optionally references a Deployment record
- Deployment record is shown with link on installation detail page
- Installation optionally references the project that owns the software

### E4-US04 — Filter and search installations

**As a** Support Engineer  
**I want to** filter a customer's installations by environment or status  
**So that** I can quickly find production installations  
**Acceptance Criteria:**

- Environment filter buttons (Production / Staging / UAT / Development / All)
- Status filter (Active / Outdated / Failed)
- Table highlights Outdated rows in yellow, Failed in red

---

## Epic 5: CI/CD Integration

### E5-US01 — CI dashboard per project

**As a** Tech Lead  
**I want to** see a dashboard of all CI runs for a project  
**So that** I can track build health over time  
**Acceptance Criteria:**

- Stat cards: total runs, passed, failed, running
- Table with build number, branch, commit SHA, duration, test counts, status
- Failed rows highlighted; click row to see full log link

### E5-US02 — Jenkins webhook integration

**As a** DevOps Engineer  
**I want to** receive Jenkins build results via webhook  
**So that** CI run records are updated in real time  
**Acceptance Criteria:**

- POST `/webhooks/jenkins` with token authentication
- Creates or updates CiRun record with status, duration, test counts
- Triggers background job to notify assignee on failure

### E5-US03 — Gitea webhook integration

**As a** DevOps Engineer  
**I want to** receive Gitea push and pull-request events via webhook  
**So that** branch and PR records stay synchronised  
**Acceptance Criteria:**

- POST `/webhooks/gitea` with HMAC signature validation
- Push event → creates/updates Branch record
- PR event → creates/updates PullRequest record
- Issue event → creates Ticket from Gitea issue

---

## Epic 6: Deployment Tracking

### E6-US01 — Record deployments

**As a** DevOps Engineer  
**I want to** record each deployment with version, environment, and deploy type  
**So that** we have a full history of what was deployed where  
**Acceptance Criteria:**

- Deploy types: Web App, Windows Installer, Windows Service, Docker
- Status: Pending → In Progress → Succeeded / Failed / Rolled Back
- Record references the project and the user who deployed

### E6-US02 — Windows installer deployments

**As a** DevOps Engineer  
**I want to** track Windows installer (Inno Setup) deployments separately  
**So that** I can report which customers have which version installed on their machines  
**Acceptance Criteria:**

- `deploy_type: windows_installer` shown distinctly
- After deployment succeeds, support team can record it as an Installation for a customer

### E6-US03 — Deployment rollback tracking

**As a** DevOps Engineer  
**I want to** mark a deployment as rolled back  
**So that** the history shows when and why a rollback occurred  
**Acceptance Criteria:**

- "Mark Rolled Back" action sets status to `rolled_back`
- Linked Installation can be updated back to previous version

---

## Epic 7: Meeting Management

### E7-US01 — Schedule team meetings

**As a** Team Lead  
**I want to** schedule meetings with agenda, duration, and meeting type  
**So that** the team has a shared calendar of upcoming sync sessions  
**Acceptance Criteria:**

- Meeting types: Daily Standup, Sprint Planning, Sprint Review, Retrospective, Demo, 1:1, Other
- Meeting has scheduled_at, duration_minutes, attendees
- Calendar export via .ics (iCalendar)

### E7-US02 — Join video meetings via Jitsi

**As a** Team member  
**I want to** click "Join" on a meeting to open a Jitsi video call  
**So that** I don't need to search for meeting links  
**Acceptance Criteria:**

- "Join" button appears when meeting is Scheduled or In Progress
- Click redirects to `<JITSI_URL>/<room-slug>`
- Jitsi iframe embed on meeting show page for in-browser joining

### E7-US03 — Meeting notes and retrospective

**As a** Team Lead  
**I want to** record notes during or after a meeting  
**So that** action items and decisions are documented  
**Acceptance Criteria:**

- `notes` field on meeting record
- Meeting can be ended (status → Completed) via "End Meeting" action
- Notes visible to all attendees in meeting history

---

## Epic 8: Documentation

### E8-US01 — Create project documents

**As a** Developer or PM  
**I want to** create documents (specs, runbooks, architecture docs) within a project  
**So that** the team has a shared knowledge base  
**Acceptance Criteria:**

- Document types: Spec, Risk Management, User Story, Timeline, Test Coverage, Architecture, Runbook, Other
- Content supports Markdown rendering via Redcarpet
- Version number field for tracking document revisions

### E8-US02 — Tag and search documents

**As a** Developer  
**I want to** tag documents and filter by type  
**So that** I can quickly find relevant documentation  
**Acceptance Criteria:**

- Tag list (comma-separated) via acts-as-taggable-on
- Filter tabs by document type on project documents page
- Full-text search on title and summary (future)

### E8-US03 — Attach files to documents

**As a** PM  
**I want to** attach PDFs or images to a document record  
**So that** binary files are stored alongside the text documentation  
**Acceptance Criteria:**

- Active Storage with local disk storage
- Attachment shown as download link on document show page
- File size and type displayed

---

## Epic 9: Notifications & Email

### E9-US01 — In-app notifications

**As a** Team member  
**I want to** receive notifications in the app when tickets are assigned to me or CI fails  
**So that** I don't miss important events  
**Acceptance Criteria:**

- Notification bell in navbar shows unread count
- Notifications page lists all unread/read notifications
- Mark read individually or all at once
- Notification links navigate to the relevant record

### E9-US02 — Email on ticket assignment

**As a** Developer  
**I want to** receive an email when a ticket is assigned to me  
**So that** I don't need to constantly check the app  
**Acceptance Criteria:**

- TicketMailer#assigned sent via background job
- Email includes ticket title, priority, project, and link
- Email is bi-lingual (respects user's preferred_language)

### E9-US03 — Email on CI failure

**As a** Developer  
**I want to** receive an email when a CI build for my ticket fails  
**So that** I am alerted immediately  
**Acceptance Criteria:**

- TicketMailer#ci_failed sent when CiRun status becomes failed
- Email includes build number, branch, failed test count, log URL

---

## Epic 10: Internationalisation (i18n)

### E10-US01 — English and Hebrew language support

**As a** Hebrew-speaking developer  
**I want to** switch the UI language to Hebrew  
**So that** I can use the application in my preferred language  
**Acceptance Criteria:**

- Language switcher in navbar switches between EN / HE instantly
- Language preference saved on user profile
- All UI labels, flash messages, and email subjects have Hebrew translations

### E10-US02 — Right-to-left (RTL) layout for Hebrew

**As a** Hebrew-speaking developer  
**I want to** see the UI in right-to-left layout when Hebrew is selected  
**So that** Hebrew text is readable in its natural direction  
**Acceptance Criteria:**

- `<html dir="rtl">` set when locale is `he`
- Navbar, tables, and form labels align right
- Bulma RTL overrides applied via custom SCSS

---

## Epic 11: Admin & Access Control

### E11-US01 — Role-based access control

**As an** Admin  
**I want to** assign roles to users (Developer, QA, Team Lead, PM, Admin)  
**So that** permissions are enforced appropriately  
**Acceptance Criteria:**

- Pundit policies control create/edit/delete per role
- Developers can only edit their own tickets
- Admins have full access

### E11-US02 — Admin user management

**As an** Admin  
**I want to** view, activate/deactivate, and change roles for all users  
**So that** I can manage the team roster  
**Acceptance Criteria:**

- Admin::UsersController with index, show, edit, update
- Can set role and active status
- Cannot delete the last admin account

### E11-US03 — Self-service profile & language settings

**As a** Developer  
**I want to** update my profile name and preferred language  
**So that** my display name and UI language are personalised  
**Acceptance Criteria:**

- Devise registrations edit page shows name + preferred_language fields
- Changing preferred_language takes effect on next page load

---

## Story Point Reference

| Size | Points | Typical Scope |
|------|--------|---------------|
| XS   | 1      | Config change, copy update |
| S    | 2      | Simple CRUD, model + route + view |
| M    | 3      | Full feature with background job or webhook |
| L    | 5      | Multi-model feature with integrations |
| XL   | 8      | Major integration (Gitea, Jenkins, full module) |

---

## Suggested Sprint Plan (4 × 2-week sprints)

### Sprint 1 — Foundation (Done ✅)

- App scaffold, Gemfile, DB, routes
- Core models (User, Project, Ticket, Sprint, Deployment, CI Run, Meeting, Document)
- Devise auth, i18n, Bulma layout

### Sprint 2 — Core Workflows

- E2-US01 Kanban board (3pt)
- E2-US03 Auto-branch on assignment (5pt)
- E5-US02 Jenkins webhook (5pt)
- E5-US03 Gitea webhook (5pt)
- E9-US01 In-app notifications (3pt)

### Sprint 3 — Customer Module (Current)

- E3-US01 Customer management (3pt)
- E3-US02 Customer support tickets (3pt)
- E3-US03 Resolve/close customer tickets (2pt)
- E4-US01 Installation tracking (3pt)
- E4-US02 Auto-outdating (2pt)
- E4-US03 Link to deployment (2pt)

### Sprint 4 — Quality & Polish

- E8-US01 Project documentation (3pt)
- E7-US01 Meeting scheduling (3pt)
- E7-US02 Jitsi join (2pt)
- E11-US01 Pundit policies (5pt)
- E10-US02 Hebrew RTL polish (2pt)
- Cucumber test suite (5pt)
