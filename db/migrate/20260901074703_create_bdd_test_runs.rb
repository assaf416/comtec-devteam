class CreateBddTestRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :bdd_test_runs do |t|
      t.references :bdd_test, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.text :output
      t.text :structured_results
      t.text :result_html
      t.string :command
      t.string :chdir
      t.datetime :started_at
      t.datetime :finished_at
      t.references :triggered_by, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
