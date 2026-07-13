# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_13_100004) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.integer "event_type", default: 9, null: false
    t.text "metadata"
    t.integer "project_id", null: false
    t.integer "subject_user_id"
    t.integer "ticket_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["event_type"], name: "index_activities_on_event_type"
    t.index ["project_id", "created_at"], name: "index_activities_on_project_id_and_created_at"
    t.index ["project_id"], name: "index_activities_on_project_id"
    t.index ["subject_user_id"], name: "index_activities_on_subject_user_id"
    t.index ["ticket_id"], name: "index_activities_on_ticket_id"
    t.index ["user_id"], name: "index_activities_on_user_id"
  end

  create_table "ai_chat_messages", force: :cascade do |t|
    t.integer "ai_chat_session_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["ai_chat_session_id"], name: "index_ai_chat_messages_on_ai_chat_session_id"
  end

  create_table "ai_chat_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "llm_model"
    t.bigint "project_id"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["project_id"], name: "index_ai_chat_sessions_on_project_id"
    t.index ["user_id"], name: "index_ai_chat_sessions_on_user_id"
  end

  create_table "ai_reviews", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "duration_ms"
    t.text "error_message"
    t.integer "kind", default: 0, null: false
    t.string "llm_model"
    t.text "prompt"
    t.integer "reviewable_id"
    t.string "reviewable_type"
    t.integer "score"
    t.integer "status", default: 0, null: false
    t.text "summary"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "verdict"
    t.index ["created_at"], name: "index_ai_reviews_on_created_at"
    t.index ["kind"], name: "index_ai_reviews_on_kind"
    t.index ["reviewable_type", "reviewable_id"], name: "index_ai_reviews_on_reviewable"
    t.index ["status"], name: "index_ai_reviews_on_status"
    t.index ["user_id"], name: "index_ai_reviews_on_user_id"
  end

  create_table "attachment_views", force: :cascade do |t|
    t.integer "attachment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.datetime "viewed_at", null: false
    t.index ["attachment_id"], name: "index_attachment_views_on_attachment_id"
    t.index ["user_id", "attachment_id"], name: "index_attachment_views_on_user_id_and_attachment_id", unique: true
    t.index ["user_id", "viewed_at"], name: "index_attachment_views_on_user_id_and_viewed_at"
    t.index ["user_id"], name: "index_attachment_views_on_user_id"
  end

  create_table "attachments", force: :cascade do |t|
    t.integer "attachable_id"
    t.string "attachable_type"
    t.datetime "created_at", null: false
    t.text "extracted_text"
    t.integer "extraction_status", default: 0, null: false
    t.integer "project_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "uploaded_by_id"
    t.index ["attachable_type", "attachable_id"], name: "index_attachments_on_attachable"
    t.index ["project_id"], name: "index_attachments_on_project_id"
    t.index ["uploaded_by_id"], name: "index_attachments_on_uploaded_by_id"
  end

  create_table "branches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "created_at_gitea"
    t.string "name"
    t.integer "project_id", null: false
    t.integer "status"
    t.integer "ticket_id", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_branches_on_project_id"
    t.index ["ticket_id"], name: "index_branches_on_ticket_id"
  end

  create_table "chat_messages", force: :cascade do |t|
    t.text "body", null: false
    t.integer "chat_room_id", null: false
    t.datetime "created_at", null: false
    t.datetime "edited_at"
    t.text "rich_refs"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["chat_room_id", "created_at"], name: "index_chat_messages_on_chat_room_id_and_created_at"
    t.index ["chat_room_id"], name: "index_chat_messages_on_chat_room_id"
    t.index ["user_id"], name: "index_chat_messages_on_user_id"
  end

  create_table "chat_rooms", force: :cascade do |t|
    t.boolean "archived", default: false, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "project_id"
    t.integer "room_type", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_chat_rooms_on_name", unique: true
    t.index ["project_id"], name: "index_chat_rooms_on_project_id"
  end

  create_table "ci_runs", force: :cascade do |t|
    t.string "branch_name"
    t.string "build_number"
    t.string "commit_sha"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.string "log_url"
    t.integer "project_id", null: false
    t.datetime "started_at"
    t.integer "status"
    t.integer "ticket_id"
    t.integer "triggered_by_id"
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_ci_runs_on_project_id"
    t.index ["ticket_id"], name: "index_ci_runs_on_ticket_id"
    t.index ["triggered_by_id"], name: "index_ci_runs_on_triggered_by_id"
  end

  create_table "client_accounts", force: :cascade do |t|
    t.string "contact_name"
    t.string "contact_phone"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.text "notes"
    t.datetime "updated_at", null: false
  end

  create_table "code_reviews", force: :cascade do |t|
    t.string "author"
    t.string "base_branch"
    t.datetime "created_at", null: false
    t.string "gitea_state"
    t.string "head_branch"
    t.integer "pr_number", null: false
    t.string "pr_url", null: false
    t.bigint "project_id"
    t.string "repo_name"
    t.string "repo_owner"
    t.bigint "reviewer_id"
    t.integer "status", default: 0, null: false
    t.text "summary"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_code_reviews_on_project_id"
    t.index ["repo_owner", "repo_name", "pr_number"], name: "index_code_reviews_on_repo_owner_and_repo_name_and_pr_number"
    t.index ["reviewer_id"], name: "index_code_reviews_on_reviewer_id"
    t.index ["status"], name: "index_code_reviews_on_status"
  end

  create_table "comments", force: :cascade do |t|
    t.integer "author_id"
    t.text "body"
    t.integer "commentable_id", null: false
    t.string "commentable_type", null: false
    t.datetime "created_at", null: false
    t.integer "kind", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_comments_on_author_id"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
  end

  create_table "customer_messages", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "customer_id", null: false
    t.boolean "internal_only", default: false, null: false
    t.bigint "sender_id", null: false
    t.string "sender_type", null: false
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_customer_messages_on_customer_id"
    t.index ["sender_type", "sender_id"], name: "index_customer_messages_on_sender"
  end

  create_table "customer_tickets", force: :cascade do |t|
    t.integer "assigned_to_id"
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "customer_id", null: false
    t.integer "internal_ticket_id"
    t.integer "priority", default: 1, null: false
    t.datetime "resolved_at"
    t.integer "status", default: 0, null: false
    t.integer "ticket_type", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_customer_tickets_on_assigned_to_id"
    t.index ["customer_id"], name: "index_customer_tickets_on_customer_id"
    t.index ["internal_ticket_id"], name: "index_customer_tickets_on_internal_ticket_id"
    t.index ["ticket_type"], name: "index_customer_tickets_on_ticket_type"
  end

  create_table "customer_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "customer_id", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_customer_users_on_customer_id"
    t.index ["email"], name: "index_customer_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_customer_users_on_reset_password_token", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "company"
    t.string "contact_person"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.text "notes"
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_customers_on_email", unique: true
    t.index ["name"], name: "index_customers_on_name"
  end

  create_table "deployments", force: :cascade do |t|
    t.integer "client_account_id"
    t.datetime "created_at", null: false
    t.integer "deploy_type"
    t.datetime "deployed_at"
    t.integer "deployed_by_id"
    t.text "env_vars"
    t.string "environment"
    t.string "ip_address"
    t.string "log_file_url"
    t.string "machine_name"
    t.text "notes"
    t.text "os_status"
    t.integer "project_id", null: false
    t.string "server_id"
    t.string "server_name"
    t.string "server_os"
    t.integer "status"
    t.datetime "updated_at", null: false
    t.string "version"
    t.index ["client_account_id"], name: "index_deployments_on_client_account_id"
    t.index ["deployed_by_id"], name: "index_deployments_on_deployed_by_id"
    t.index ["ip_address"], name: "index_deployments_on_ip_address"
    t.index ["project_id"], name: "index_deployments_on_project_id"
  end

  create_table "documents", force: :cascade do |t|
    t.integer "author_id"
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "doc_type"
    t.boolean "is_template", default: false, null: false
    t.integer "project_id", null: false
    t.text "summary"
    t.integer "template_id"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "version_number"
    t.index ["author_id"], name: "index_documents_on_author_id"
    t.index ["is_template"], name: "index_documents_on_is_template"
    t.index ["project_id"], name: "index_documents_on_project_id"
    t.index ["template_id"], name: "index_documents_on_template_id"
  end

  create_table "installations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "customer_id", null: false
    t.integer "deployment_id"
    t.string "environment", default: "production", null: false
    t.datetime "installed_at"
    t.text "notes"
    t.integer "project_id"
    t.string "software_name", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "version", null: false
    t.index ["customer_id", "software_name"], name: "index_installations_on_customer_id_and_software_name"
    t.index ["customer_id"], name: "index_installations_on_customer_id"
    t.index ["deployment_id"], name: "index_installations_on_deployment_id"
    t.index ["project_id"], name: "index_installations_on_project_id"
    t.index ["status"], name: "index_installations_on_status"
  end

  create_table "meeting_attendees", force: :cascade do |t|
    t.boolean "attended"
    t.datetime "created_at", null: false
    t.integer "meeting_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["meeting_id"], name: "index_meeting_attendees_on_meeting_id"
    t.index ["user_id"], name: "index_meeting_attendees_on_user_id"
  end

  create_table "meetings", force: :cascade do |t|
    t.text "agenda"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "duration_minutes"
    t.string "jitsi_room"
    t.integer "meeting_type"
    t.text "notes"
    t.integer "organizer_id"
    t.integer "project_id"
    t.string "recording_url"
    t.datetime "scheduled_at"
    t.integer "status"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["organizer_id"], name: "index_meetings_on_organizer_id"
    t.index ["project_id"], name: "index_meetings_on_project_id"
  end

  create_table "milestones", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.date "due_date"
    t.string "name"
    t.integer "project_id", null: false
    t.integer "status"
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_milestones_on_project_id"
  end

  create_table "notes", force: :cascade do |t|
    t.boolean "archived", default: false, null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.boolean "pinned", default: false, null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "archived", "pinned"], name: "index_notes_on_user_id_and_archived_and_pinned"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.text "backtrace"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.text "message"
    t.text "params"
    t.datetime "read_at"
    t.bigint "recipient_id"
    t.string "recipient_type"
    t.string "type"
    t.datetime "updated_at", null: false
  end

  create_table "project_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "notes"
    t.integer "project_id", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["project_id", "user_id"], name: "index_project_memberships_on_project_id_and_user_id", unique: true
    t.index ["project_id"], name: "index_project_memberships_on_project_id"
    t.index ["user_id"], name: "index_project_memberships_on_user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.string "default_branch"
    t.text "description"
    t.string "gitea_repo_id"
    t.string "name"
    t.string "repo_url"
    t.string "tech_stack"
    t.datetime "updated_at", null: false
  end

  create_table "pull_requests", force: :cascade do |t|
    t.string "author"
    t.text "build_errors"
    t.text "code_changed"
    t.decimal "coverage_percent", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.text "description"
    t.text "files_changed"
    t.text "files_data"
    t.string "gitea_url"
    t.text "latest_test_results"
    t.datetime "merged_at"
    t.text "pr_comments_data"
    t.integer "pr_number"
    t.integer "project_id", null: false
    t.integer "status"
    t.datetime "synced_at"
    t.text "test_code"
    t.text "tests_data"
    t.integer "ticket_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_pull_requests_on_project_id"
    t.index ["ticket_id"], name: "index_pull_requests_on_ticket_id"
  end

  create_table "server_heartbeats", force: :cascade do |t|
    t.integer "cpu"
    t.datetime "created_at", null: false
    t.integer "disk"
    t.integer "error_count", default: 0
    t.string "ip_address", null: false
    t.string "log_file_url"
    t.integer "mem"
    t.datetime "recorded_at", null: false
    t.string "server_name"
    t.string "server_os"
    t.datetime "updated_at", null: false
    t.index ["ip_address", "recorded_at"], name: "index_server_heartbeats_on_ip_address_and_recorded_at"
    t.index ["ip_address"], name: "index_server_heartbeats_on_ip_address"
  end

  create_table "taggings", force: :cascade do |t|
    t.string "context", limit: 128
    t.datetime "created_at", precision: nil
    t.integer "tag_id"
    t.integer "taggable_id"
    t.string "taggable_type"
    t.integer "tagger_id"
    t.string "tagger_type"
    t.string "tenant", limit: 128
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "taggings_taggable_context_idx"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable_type_and_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
    t.index ["tagger_type", "tagger_id"], name: "index_taggings_on_tagger_type_and_tagger_id"
    t.index ["tenant"], name: "index_taggings_on_tenant"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "taggings_count", default: 0
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "tasks", force: :cascade do |t|
    t.string "actual"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "estimation"
    t.datetime "started_at"
    t.integer "ticket_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["ticket_id"], name: "index_tasks_on_ticket_id"
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "test_results", force: :cascade do |t|
    t.integer "ci_run_id", null: false
    t.datetime "created_at", null: false
    t.integer "duration_ms"
    t.integer "failed"
    t.integer "passed"
    t.integer "skipped"
    t.string "suite_name"
    t.integer "total"
    t.datetime "updated_at", null: false
    t.text "xml_report"
    t.index ["ci_run_id"], name: "index_test_results_on_ci_run_id"
  end

  create_table "ticket_watchers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "ticket_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["ticket_id"], name: "index_ticket_watchers_on_ticket_id"
    t.index ["user_id"], name: "index_ticket_watchers_on_user_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.string "actual_hours"
    t.integer "actual_velocity"
    t.datetime "approved_at"
    t.integer "assignee_id"
    t.string "branch_name"
    t.integer "completed_tasks_count", default: 0
    t.decimal "completed_tasks_estimation", precision: 8, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.text "description"
    t.decimal "dev_estimate_hours", precision: 6, scale: 2
    t.integer "estimated_by_id"
    t.integer "github_issue_number"
    t.string "github_state"
    t.datetime "github_synced_at"
    t.string "github_url"
    t.text "how_to_reproduce"
    t.integer "kind", default: 0, null: false
    t.integer "latest_ci_run_id"
    t.integer "level", default: 2, null: false
    t.integer "milestone_id"
    t.bigint "owner_id"
    t.integer "pr_number"
    t.string "pr_url"
    t.integer "priority"
    t.integer "project_id", null: false
    t.integer "status"
    t.integer "story_points"
    t.integer "tasks_count", default: 0
    t.integer "tasks_progress_in_percents", default: 0
    t.text "test_plan"
    t.decimal "tester_estimate_hours", precision: 6, scale: 2
    t.string "title"
    t.decimal "total_tasks_estimation", precision: 8, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.index ["assignee_id"], name: "index_tickets_on_assignee_id"
    t.index ["estimated_by_id"], name: "index_tickets_on_estimated_by_id"
    t.index ["kind"], name: "index_tickets_on_kind"
    t.index ["level"], name: "index_tickets_on_level"
    t.index ["milestone_id"], name: "index_tickets_on_milestone_id"
    t.index ["owner_id"], name: "index_tickets_on_owner_id"
    t.index ["project_id", "github_issue_number"], name: "index_tickets_on_project_and_github_issue", unique: true, where: "github_issue_number IS NOT NULL"
    t.index ["project_id"], name: "index_tickets_on_project_id"
  end

  create_table "time_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "hours", precision: 6, scale: 2, default: "0.0", null: false
    t.text "note"
    t.integer "project_id", null: false
    t.date "spent_on", null: false
    t.integer "ticket_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["project_id", "spent_on"], name: "index_time_logs_on_project_id_and_spent_on"
    t.index ["project_id"], name: "index_time_logs_on_project_id"
    t.index ["ticket_id"], name: "index_time_logs_on_ticket_id"
    t.index ["user_id", "spent_on"], name: "index_time_logs_on_user_id_and_spent_on"
    t.index ["user_id"], name: "index_time_logs_on_user_id"
  end

  create_table "todo_items", force: :cascade do |t|
    t.string "content", null: false
    t.datetime "created_at", null: false
    t.boolean "done", default: false, null: false
    t.integer "position", default: 0, null: false
    t.integer "todo_list_id", null: false
    t.datetime "updated_at", null: false
    t.index ["todo_list_id", "position"], name: "index_todo_items_on_todo_list_id_and_position"
    t.index ["todo_list_id"], name: "index_todo_items_on_todo_list_id"
  end

  create_table "todo_lists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_todo_lists_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "api_token"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "github_login"
    t.string "name"
    t.string "preferred_language"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role"
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["github_login"], name: "index_users_on_github_login"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activities", "projects"
  add_foreign_key "activities", "tickets"
  add_foreign_key "activities", "users"
  add_foreign_key "activities", "users", column: "subject_user_id"
  add_foreign_key "ai_chat_messages", "ai_chat_sessions"
  add_foreign_key "attachment_views", "attachments"
  add_foreign_key "attachment_views", "users"
  add_foreign_key "attachments", "projects"
  add_foreign_key "attachments", "users", column: "uploaded_by_id"
  add_foreign_key "branches", "projects"
  add_foreign_key "branches", "tickets"
  add_foreign_key "chat_messages", "chat_rooms"
  add_foreign_key "chat_messages", "users"
  add_foreign_key "chat_rooms", "projects"
  add_foreign_key "ci_runs", "projects"
  add_foreign_key "ci_runs", "tickets"
  add_foreign_key "ci_runs", "users", column: "triggered_by_id"
  add_foreign_key "comments", "users", column: "author_id"
  add_foreign_key "customer_messages", "customers"
  add_foreign_key "customer_tickets", "customers"
  add_foreign_key "customer_tickets", "tickets", column: "internal_ticket_id"
  add_foreign_key "customer_tickets", "users", column: "assigned_to_id"
  add_foreign_key "customer_users", "customers"
  add_foreign_key "deployments", "client_accounts"
  add_foreign_key "deployments", "projects"
  add_foreign_key "deployments", "users", column: "deployed_by_id"
  add_foreign_key "documents", "projects"
  add_foreign_key "documents", "users", column: "author_id"
  add_foreign_key "installations", "customers"
  add_foreign_key "installations", "deployments"
  add_foreign_key "installations", "projects"
  add_foreign_key "meeting_attendees", "meetings"
  add_foreign_key "meeting_attendees", "users"
  add_foreign_key "meetings", "projects"
  add_foreign_key "meetings", "users", column: "organizer_id"
  add_foreign_key "milestones", "projects"
  add_foreign_key "notes", "users"
  add_foreign_key "project_memberships", "projects"
  add_foreign_key "project_memberships", "users"
  add_foreign_key "pull_requests", "projects"
  add_foreign_key "pull_requests", "tickets"
  add_foreign_key "taggings", "tags"
  add_foreign_key "tasks", "tickets"
  add_foreign_key "test_results", "ci_runs"
  add_foreign_key "ticket_watchers", "tickets"
  add_foreign_key "ticket_watchers", "users"
  add_foreign_key "tickets", "milestones"
  add_foreign_key "tickets", "projects"
  add_foreign_key "tickets", "users", column: "assignee_id"
  add_foreign_key "tickets", "users", column: "estimated_by_id"
  add_foreign_key "tickets", "users", column: "owner_id"
  add_foreign_key "time_logs", "projects"
  add_foreign_key "time_logs", "tickets"
  add_foreign_key "time_logs", "users"
  add_foreign_key "todo_items", "todo_lists"
  add_foreign_key "todo_lists", "users"
end
