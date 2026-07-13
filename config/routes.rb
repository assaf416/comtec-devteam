Rails.application.routes.draw do
  # ── DevTeam CLI / VS Code Extension API ─────────────────────────────────
  namespace :api do
    namespace :v1 do
      get  "me",               to: "users#me"
      get  "token",            to: "users#token"
      post "token/regenerate", to: "users#regenerate_token"
      resources :tickets,  only: %i[index show]
      resources :pull_requests, only: %i[index show create]
      resources :ci_runs, only: %i[index show create] do
        resources :test_results, only: %i[index create], module: :ci_runs
      end
      resources :deployments, only: %i[index show create update]
      resources :projects, only: %i[index show]
      post "checkout", to: "checkout#create"

      # Logs — Loki proxy
      get  "logs",          to: "logs#index"
      get  "logs/services", to: "logs#services"
      post "logs/push",     to: "logs#push"
      get  "logs/stats",    to: "logs#stats"

      # Heartbeat ingestion from remote machines (OS telemetry)
      resources :heartbeats, only: %i[create]
    end
  end

  # Top-level documents overview (across all projects)
  get "documents", to: "all_documents#index", as: :all_documents

  get "admin/users"
  get "admin/client_accounts"
  get "admin/settings"
  get "reports/ci_summary"
  get "reports/deployment_summary"
  get "reports/test_coverage"
  get "reports/estimation_accuracy"

  # ── CI Dashboard ────────────────────────────────────────────────────────────
  get "ci",             to: "ci_dashboard#index",       as: :ci_dashboard
  get "ci/runs",        to: "ci_dashboard#runs",         as: :ci_runs_all
  get "ci/security",    to: "ci_dashboard#security",     as: :ci_security
  get "ci/performance", to: "ci_dashboard#performance",  as: :ci_performance

  # ── Quick contact (toolbar: message a teammate) ─────────────────────────────
  post "quick_contact", to: "quick_contacts#create", as: :quick_contact

  # ── Cucumber feature-file editor (dark console + Gherkin highlighting) ───────
  get  "cucumber_tests/edit",   to: "cucumber_tests#edit",   as: :edit_cucumber_test
  post "cucumber_tests/review", to: "cucumber_tests#review", as: :review_cucumber_test


  # ── Server / remote-machine monitoring (heartbeats) ─────────────────────────
  get "servers",        to: "servers#index",   as: :servers
  get "server",         to: "servers#show",    as: :server          # ?ip=<ip_address>
  get  "server/console", to: "servers#console", as: :server_console # ?ip=<ip_address>
  post "server/docker",  to: "servers#docker",  as: :server_docker

  # ── Deploy console (wraps the external deploy backend) ──────────────────────
  get  "deploy", to: "deploy#index",  as: :deploy
  post "deploy", to: "deploy#create"

  # ── Release timeline + rollback ─────────────────────────────────────────────
  get  "releases",             to: "releases#index",    as: :releases
  post "releases/:id/rollback", to: "releases#rollback", as: :rollback_release

  # ── AI chat terminal (agentic console) ──────────────────────────────────────
  get  "assistant",         to: "assistant#index",   as: :assistant
  post "assistant/message", to: "assistant#message", as: :assistant_message
  post "assistant/clear",   to: "assistant#clear",   as: :assistant_clear

  # ── Log Viewer (reads the central Loki store) ───────────────────────────────
  get "logs",      to: "log_viewer#index", as: :log_viewer
  get "logs/tail", to: "log_viewer#tail",  as: :log_viewer_tail

  # ── Code Review (review a Gitea PR by URL) ──────────────────────────────────
  resources :code_reviews, only: %i[index new create show update] do
    member do
      post :refresh
      post :ai_review
    end
    resources :comments, only: %i[create destroy], controller: "code_review_comments"
  end

  # ── AI Agent (local Ollama LLM on the on-prem Mac mini) ─────────────────────
  namespace :tools do
    get "ai",              to: "ai#index",        as: :ai             # AI Reports dashboard
    get "ai/reviews",      to: "ai#reviews",      as: :ai_reviews     # Recent (code) review results
    get "ai/test_reviews", to: "ai#test_reviews", as: :ai_test_reviews
    get "ai/reviews/:id",  to: "ai#show",         as: :ai_review

    # Service endpoints — each contacts the Ollama machine and persists an AiReview
    post "ai/ticket_quality",      to: "ai#ticket_quality",      as: :ai_ticket_quality
    post "ai/code_review",         to: "ai#code_review",         as: :ai_code_review
    post "ai/test_review",         to: "ai#test_review",         as: :ai_test_review
    post "ai/estimation_analysis", to: "ai#estimation_analysis", as: :ai_estimation_analysis
    post "ai/solution_suggestion", to: "ai#solution_suggestion", as: :ai_solution_suggestion
    post "ai/fix_bug",             to: "ai#fix_bug",             as: :ai_fix_bug
    post "ai/generate_tasks",      to: "ai#generate_tasks",      as: :ai_generate_tasks
  end

  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }

  # User profile (separate from Devise registrations)
  resource :profile, only: %i[edit update], controller: "profile"

  # ── Customer Portal ──────────────────────────────────────────────────────
  devise_for :customer_users,
             path: "portal",
             path_names: { sign_in: "login", sign_out: "logout" },
             controllers: { sessions: "customer_portal/sessions" },
             skip: %i[registrations confirmations unlocks]

  namespace :customer_portal, path: "portal" do
    root "dashboard#index"
    resources :tickets,    only: %i[index show new create]
    resources :messages,   only: %i[index create]
    resources :milestones, only: %i[index]
    resources :documents,  only: %i[index show]
  end
  # ─────────────────────────────────────────────────────────────────────────

  root "dashboard#index"
  get "dashboard", to: "dashboard#index", as: :dashboard
  get "today",     to: "today#index",     as: :today

  # Time logging (רישום שעות)
  resources :time_logs, only: %i[index create destroy]

  # Personal notes (פתקים)
  resources :notes, only: %i[index create update destroy] do
    member do
      patch :toggle_pin
      patch :toggle_archive
    end
  end

  # Personal to-do lists (משימות)
  resources :todo_lists, only: %i[index create update destroy] do
    resources :todo_items, only: %i[create update destroy] do
      member { patch :toggle }
    end
  end
  get "calendar",  to: "calendar#index",  as: :calendar

  # ── Ticket views (cross-project) ────────────────────────────────────────
  get "tickets",                to: "tickets#all",            as: :all_tickets
  get "tickets/mine",           to: "tickets#mine",           as: :my_tickets
  get "tickets/late",           to: "tickets#late",           as: :late_tickets
  get "tickets/backlog",        to: "tickets#backlog_list",   as: :backlog_tickets
  get "calendar/events", to: "calendar#events", as: :calendar_events

  resources :customers do
    resources :customer_tickets do
      member do
        patch :resolve
        patch :link_ticket
      end
    end
    resources :installations
  end

  resources :projects do
    # Chat with AI — scoped to the project (code context = the project's repo)
    resources :ai_chats, only: %i[index create show], shallow: true do
      member do
        post :message
        post :open_issues   # approve a task-list proposal → open GitHub issues
      end
    end
    resources :tickets, only: %i[index show], shallow: true
    resources :milestones, shallow: true
    resources :ci_runs, only: [ :index, :show ], shallow: true
    resources :deployments, shallow: true
    resources :documents, shallow: true do
      collection do
        get  :templates
        post :generate   # AI-generate a document (presentation / spec) for the project
      end
      member do
        post :save_as_template
        get  :new_from_template
        get  :raw
      end
    end
    resources :branches, only: [ :index, :show ], shallow: true
    resources :pull_requests, only: [ :index, :show ], shallow: true do
      member do
        post :sync
        get  :cockpit
        post :merge
      end
    end
    resources :project_memberships, only: %i[create destroy]
    resources :activities,           only: %i[index]
    member do
      get  :dashboard
      get  :report
      get  :ci_dashboard
      get  :calendar_events
      post :sync_issues   # pull GitHub issues into this project's tickets
    end
  end

  resources :meetings do
    member do
      post :join
      post :end_meeting
      get  :ical
      post :invite
      patch :save_recording
    end
    resources :comments, only: %i[create destroy], controller: "meeting_comments"
    collection { get :project_meetings, path: "project/:project_id" }
  end

  # project-scoped meeting index (e.g. linked from project page)
  get "projects/:project_id/meetings", to: "meetings#index", as: :project_meetings

  resources :notifications do
    collection { post :mark_all_read }
    member do
      patch :mark_read
      post  :open_ticket   # create a ticket from this notification's data
    end
  end

  resources :chat_rooms, only: %i[index show new create] do
    resources :chat_messages, only: %i[create]
  end

  # Ticket comments — derived from ticket (project resolved via ticket.project)
  resources :tickets, only: [] do
    resources :comments, only: %i[create destroy]
    resources :tasks, only: %i[create update destroy] do
      member do
        patch :start
        patch :complete
        patch :reopen
      end
    end
  end

  # Webhooks (no CSRF – verified by secret header)
  post "webhooks/gitea",      to: "webhooks#gitea"
  post "webhooks/jenkins",    to: "webhooks#jenkins"
  post "webhooks/exception",  to: "webhooks#exception"

  namespace :reports do
    get :ci_summary
    get :deployment_summary
    get :test_coverage
    get :estimation_accuracy
  end

  namespace :admin do
    resources :users
    resources :client_accounts
    get :settings
    patch :settings, to: "admin#update_settings"
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest"       => "rails/pwa#manifest",       as: :pwa_manifest

  # ── Mobile UI ───────────────────────────────────────────────────────────────
  scope :mobile, as: :mobile do
    get "today",       to: "mobile#today",       as: :today
    get "messages",    to: "mobile#messages",    as: :messages
    get "meetings",    to: "mobile#meetings",    as: :meetings
    get "projects",    to: "mobile#projects",    as: :projects
    get "project/:id", to: "mobile#project",     as: :project
    get "tickets",     to: "mobile#tickets",     as: :tickets
    get "ticket/:id",  to: "mobile#ticket",      as: :ticket
    get "video-calls", to: "mobile#video_calls", as: :video_calls
    root to: "mobile#today", as: :root
  end
end
