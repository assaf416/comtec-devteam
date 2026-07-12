class CreateTestResults < ActiveRecord::Migration[8.1]
  def change
    create_table :test_results do |t|
      t.references :ci_run, null: false, foreign_key: true
      t.string :suite_name
      t.integer :total
      t.integer :passed
      t.integer :failed
      t.integer :skipped
      t.integer :duration_ms
      t.text :xml_report

      t.timestamps
    end
  end
end
