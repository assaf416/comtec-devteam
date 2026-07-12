class CreateTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets do |t|
      t.string :title
      t.text :description
      t.integer :status
      t.integer :priority
      t.references :project, null: false, foreign_key: true
      t.references :sprint, null: true, foreign_key: true
      t.references :assignee, null: true, foreign_key: { to_table: :users }
      t.string :branch_name
      t.integer :pr_number
      t.integer :latest_ci_run_id
      t.integer :story_points

      t.timestamps
    end
  end
end
