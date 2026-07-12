class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :ticket, null: false, foreign_key: true
      t.bigint  :user_id                 # assignee (optional — may be unassigned)
      t.text    :description, null: false
      t.string  :estimation              # e.g. "4h", "2d" (free-form, like ticket actual_hours)
      t.string  :actual                  # actual time spent (free-form)
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :tasks, :user_id
  end
end
