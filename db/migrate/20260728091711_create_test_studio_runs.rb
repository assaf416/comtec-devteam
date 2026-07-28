class CreateTestStudioRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :test_studio_runs do |t|
      t.string :feature_path, null: false
      t.integer :status, null: false, default: 0
      t.text :output
      t.datetime :started_at
      t.datetime :finished_at
      t.references :triggered_by, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    add_index :test_studio_runs, :feature_path
  end
end
