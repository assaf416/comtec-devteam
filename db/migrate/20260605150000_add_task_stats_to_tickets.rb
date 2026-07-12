class AddTaskStatsToTickets < ActiveRecord::Migration[8.1]
  def change
    # Cached, denormalised rollups of a ticket's tasks. Kept in sync by a Task
    # after_commit hook (Ticket#recalculate_task_stats!). Dashboards read these
    # directly instead of recomputing per request.
    add_column :tickets, :total_tasks_estimation,     :decimal, precision: 8, scale: 2, default: 0
    add_column :tickets, :tasks_progress_in_percents, :integer, default: 0
    add_column :tickets, :tasks_count,                :integer, default: 0
    add_column :tickets, :completed_tasks_count,      :integer, default: 0
  end
end
