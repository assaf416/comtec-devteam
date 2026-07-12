class AddCompletedTasksEstimationToTickets < ActiveRecord::Migration[8.1]
  def change
    # Hours of the *completed* tasks — powers the "progress in hours" badge
    # (completed / total estimated hours). Kept in sync with the other task
    # rollups by Ticket#recalculate_task_stats!.
    add_column :tickets, :completed_tasks_estimation, :decimal, precision: 8, scale: 2, default: 0
  end
end
