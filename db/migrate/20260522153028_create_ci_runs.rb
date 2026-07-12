class CreateCiRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :ci_runs do |t|
      t.references :project, null: false, foreign_key: true
      t.references :ticket, null: true, foreign_key: true
      t.string :build_number
      t.integer :status
      t.datetime :started_at
      t.datetime :finished_at
      t.string :log_url
      t.references :triggered_by, null: true, foreign_key: { to_table: :users }
      t.string :branch_name
      t.string :commit_sha

      t.timestamps
    end
  end
end
