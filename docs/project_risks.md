# DevTeam Hub — Project Risk Register

> **Document type:** Risk Management  
> **Version:** 1.0  
> **Last updated:** May 22, 2026  
> **Owner:** Engineering Lead  

---

## Risk Rating Matrix

| Likelihood \ Impact | Low (1) | Medium (2) | High (3) |
|---|---|---|---|
| **Low (1)** | 1 — Negligible | 2 — Minor | 3 — Moderate |
| **Medium (2)** | 2 — Minor | 4 — Moderate | 6 — Significant |
| **High (3)** | 3 — Moderate | 6 — Significant | 9 — Critical |

**Thresholds:** ≤ 2 Monitor · 3–4 Mitigate · 6–9 Immediate action

---

## Risk Register

### R01 — SQLite3 scalability ceiling

| Field | Detail |
|---|---|
| **Category** | Technical / Infrastructure |
| **Description** | SQLite3 is used as the primary database. Under high concurrent write loads (many users triggering CI events, webhooks, and notifications simultaneously) SQLite's file-level locking may cause `SQLITE_BUSY` errors and degraded performance. |
| **Likelihood** | Medium (2) |
| **Impact** | High (3) |
| **Score** | **6 — Significant** |
| **Affected components** | All database operations; especially webhook receivers, Solid Queue, Solid Cable |
| **Trigger point** | > 10 concurrent users performing write operations, or > 50 webhook events/minute |
| **Mitigation** | • Implement WAL mode (`PRAGMA journal_mode=WAL`) — already partially mitigated by Rails 8 SQLite defaults<br>• Keep Solid Queue on a separate SQLite database file<br>• Establish a clear migration path to PostgreSQL (schema and models are compatible; only `serialize :params` needs reversion) |
| **Contingency** | Switch to PostgreSQL; Gemfile and schema changes are small (swap `gem "sqlite3"` → `gem "pg"`, revert `t.text "params"` to `t.jsonb`, remove `serialize` in Notification model) |
| **Owner** | DevOps / Backend Lead |
| **Review date** | Before production launch |

---

### R02 — macOS com.apple.provenance xattr on SQLite files

| Field | Detail |
|---|---|
| **Category** | Development environment / Tooling |
| **Description** | On macOS, files created in certain directories automatically receive the `com.apple.provenance` extended attribute. The SQLite3 Ruby gem (~> 2.0) refuses to open files with this attribute, causing database connection errors at startup. |
| **Likelihood** | High (3) — affects all macOS developers |
| **Impact** | Medium (2) |
| **Score** | **6 — Significant** |
| **Affected components** | Local development and test databases |
| **Trigger point** | Any run of `rails db:create` or automatic file creation in `db/` |
| **Mitigation** | • Document the workaround in README: create SQLite files via the `sqlite3` CLI tool before running migrations<br>• Add a `bin/setup` script that runs `sqlite3 db/development.sqlite3 ".quit"` instead of `rails db:create`<br>• Consider adding `xattr -d com.apple.provenance db/*.sqlite3` to `bin/setup` |
| **Contingency** | Use Docker for local development to avoid macOS filesystem quirks |
| **Owner** | All developers — environment setup documented |
| **Review date** | Ongoing |

---

### R03 — Jenkins / Gitea webhook authentication bypass

| Field | Detail |
|---|---|
| **Category** | Security |
| **Description** | The webhook endpoints (`POST /webhooks/gitea`, `POST /webhooks/jenkins`) skip CSRF protection. If the shared secret or HMAC key is weak, guessable, or accidentally exposed (e.g. in logs or environment variables), an attacker could inject fake CI results or branch events. |
| **Likelihood** | Low (1) |
| **Impact** | High (3) |
| **Score** | **3 — Moderate** |
| **Affected components** | `WebhooksController`, CI runs, branches, pull requests |
| **Mitigation** | • Enforce HMAC-SHA256 signature validation on every request<br>• Use `ActiveSupport::SecurityUtils.secure_compare` for timing-safe comparison<br>• Rotate webhook secrets quarterly<br>• Rate-limit the webhook endpoints (Rack::Attack)<br>• Never log raw webhook payloads |
| **Contingency** | Disable webhook endpoints until secrets are rotated; replay CI results manually |
| **Owner** | Security / Backend Lead |
| **Review date** | Pre-launch security review |

---

### R04 — Pundit policies not implemented on Customer module

| Field | Detail |
|---|---|
| **Category** | Security / Access Control |
| **Description** | `ApplicationController` includes `Pundit::Authorization`, but `CustomersController`, `CustomerTicketsController`, and `InstallationsController` do not currently call `authorize` before actions. Any authenticated user can read, create, edit, or delete customer data regardless of their role. |
| **Likelihood** | Medium (2) |
| **Impact** | High (3) |
| **Score** | **6 — Significant** |
| **Affected components** | `/customers/**` routes; customer, customer_ticket, installation data |
| **Mitigation** | • Create `CustomerPolicy`, `CustomerTicketPolicy`, `InstallationPolicy` Pundit policy classes<br>• Add `authorize @customer` calls in each controller action<br>• Restrict write access to `team_lead`, `project_manager`, `admin` roles<br>• Add `after_action :verify_authorized` in controllers as a safety net |
| **Contingency** | Apply IP allowlisting at the reverse-proxy level while policies are built |
| **Owner** | Backend Lead |
| **Review date** | Sprint 4 |

---

### R05 — Missing mailer view templates

| Field | Detail |
|---|---|
| **Category** | Functionality |
| **Description** | `TicketMailer` references views for `assigned`, `status_changed`, `ci_failed`, and `deploy_failed` actions, but the HTML/text template files have not been created. Any email dispatch will raise `ActionView::MissingTemplate` in production. |
| **Likelihood** | High (3) — code paths are exercised |
| **Impact** | Medium (2) |
| **Score** | **6 — Significant** |
| **Affected components** | `TicketMailer`, all notification background jobs |
| **Mitigation** | Create the four missing mailer view files in `app/views/ticket_mailer/` |
| **Contingency** | Rescue `ActionView::MissingTemplate` in mailer base class and log error |
| **Owner** | Backend developer |
| **Review date** | Next sprint |

---

### R06 — SprintsController stub (no implementation)

| Field | Detail |
|---|---|
| **Category** | Functionality |
| **Description** | `SprintsController` exists as a scaffold stub with no action implementations. Sprint-related routes will return blank or error pages. |
| **Likelihood** | High (3) |
| **Impact** | Medium (2) |
| **Score** | **6 — Significant** |
| **Affected components** | `/projects/:id/sprints/**` |
| **Mitigation** | Implement full CRUD in SprintsController with sprint ticket assignment support |
| **Owner** | Backend developer |
| **Review date** | Sprint 2 |

---

### R07 — Reports namespace controller conflict

| Field | Detail |
|---|---|
| **Category** | Technical |
| **Description** | A top-level `app/controllers/reports_controller.rb` and a `namespace :reports` block in routes.rb both exist. Rails will route namespaced report paths to `app/controllers/reports/` subdirectory controllers which may not all exist, causing `uninitialized constant` errors. |
| **Likelihood** | Medium (2) |
| **Impact** | Medium (2) |
| **Score** | **4 — Moderate** |
| **Affected components** | `/reports/**` routes |
| **Mitigation** | • Remove the flat `reports_controller.rb` and consolidate all report logic under `app/controllers/reports/` namespace<br>• Create `reports/ci_summary_controller.rb`, `reports/deployment_summary_controller.rb`, etc. |
| **Owner** | Backend developer |
| **Review date** | Sprint 2 |

---

### R08 — Milestone migration may be missing milestone_id on tickets

| Field | Detail |
|---|---|
| **Category** | Data Integrity |
| **Description** | `Ticket` has `belongs_to :milestone, optional: true` but the schema shows no `milestone_id` column under tickets. If the migration was not run, ActiveRecord will raise `ActiveModel::MissingAttributeError` when accessing `ticket.milestone`. |
| **Likelihood** | Medium (2) |
| **Impact** | Medium (2) |
| **Score** | **4 — Moderate** |
| **Mitigation** | Verify: `rails runner "puts Ticket.column_names.include?('milestone_id')"`. If false, generate `rails g migration AddMilestoneToTickets milestone:references` and migrate. |
| **Owner** | Backend developer |
| **Review date** | Immediate |

---

### R09 — i18n translation keys missing for new models

| Field | Detail |
|---|---|
| **Category** | UX / Localisation |
| **Description** | Controllers for Customer, CustomerTicket, and Installation reference translation keys such as `t("customers.created")` which have not been added to `config/locales/en.yml` or `config/locales/he.yml`. Views will display raw translation key strings instead of human-readable labels. |
| **Likelihood** | High (3) |
| **Impact** | Low (1) |
| **Score** | **3 — Moderate** |
| **Mitigation** | Add all missing translation keys to both locale files |
| **Owner** | Frontend / i18n maintainer |
| **Review date** | Next sprint |

---

### R10 — No rate limiting on authentication endpoints

| Field | Detail |
|---|---|
| **Category** | Security |
| **Description** | Devise sign-in and password reset endpoints have no rate limiting. They are vulnerable to brute-force and credential-stuffing attacks. |
| **Likelihood** | Medium (2) |
| **Impact** | High (3) |
| **Score** | **6 — Significant** |
| **Mitigation** | • Add `rack-attack` gem<br>• Throttle `POST /users/sign_in` to 10 requests per IP per 20 seconds<br>• Throttle password reset to 5 per IP per hour<br>• Block IPs with > 100 failed attempts per day |
| **Owner** | Security / DevOps |
| **Review date** | Pre-launch |

---

### R11 — Solid Queue requires a separate SQLite file

| Field | Detail |
|---|---|
| **Category** | Infrastructure |
| **Description** | Solid Queue, Solid Cache, and Solid Cable each write to the main application database by default. Mixing job queue writes with application writes on a single SQLite file increases lock contention. |
| **Likelihood** | Medium (2) |
| **Impact** | Medium (2) |
| **Score** | **4 — Moderate** |
| **Mitigation** | Configure `config/database.yml` to use separate SQLite files for queue, cache, and cable (e.g. `db/queue.sqlite3`, `db/cache.sqlite3`, `db/cable.sqlite3`) |
| **Owner** | DevOps / Backend Lead |
| **Review date** | Pre-launch |

---

### R12 — Single-developer bus factor

| Field | Detail |
|---|---|
| **Category** | Organisational |
| **Description** | If the project was largely built by one developer, significant domain knowledge (webhook integration, SQLite workarounds, enum conventions) exists only in one person's head. |
| **Likelihood** | High (3) |
| **Impact** | High (3) |
| **Score** | **9 — Critical** |
| **Mitigation** | • Maintain this documentation set<br>• Pair-programming sessions on complex modules (webhooks, notifications)<br>• Code review required for all PRs (minimum one reviewer)<br>• Record architecture decision records (ADRs) in `docs/` |
| **Owner** | Engineering Lead / PM |
| **Review date** | Ongoing |

---

### R13 — Active Storage local disk in production

| Field | Detail |
|---|---|
| **Category** | Infrastructure |
| **Description** | Active Storage is configured for local disk storage. File attachments (document PDFs, etc.) will be lost if the server is replaced or the disk is wiped. Not suitable for multi-instance deployments. |
| **Likelihood** | Medium (2) |
| **Impact** | High (3) |
| **Score** | **6 — Significant** |
| **Mitigation** | Configure S3-compatible storage (e.g. MinIO for on-premise, S3 for cloud) before going to production |
| **Owner** | DevOps |
| **Review date** | Pre-launch |

---

## Risk Summary Table

| ID | Title | Score | Status |
|---|---|---|---|
| R01 | SQLite scalability ceiling | 6 — Significant | Open |
| R02 | macOS xattr on SQLite files | 6 — Significant | Partially mitigated |
| R03 | Webhook authentication bypass | 3 — Moderate | Open |
| R04 | Pundit policies missing on Customer | 6 — Significant | Open |
| R05 | Missing mailer view templates | 6 — Significant | Open |
| R06 | SprintsController stub | 6 — Significant | Open |
| R07 | Reports namespace conflict | 4 — Moderate | Open |
| R08 | milestone_id missing on tickets | 4 — Moderate | Open |
| R09 | i18n keys missing | 3 — Moderate | Open |
| R10 | No rate limiting on auth | 6 — Significant | Open |
| R11 | Solid Queue on shared DB file | 4 — Moderate | Open |
| R12 | Single-developer bus factor | 9 — Critical | Open |
| R13 | Active Storage on local disk | 6 — Significant | Open |
