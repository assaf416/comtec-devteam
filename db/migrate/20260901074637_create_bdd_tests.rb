class CreateBddTests < ActiveRecord::Migration[8.1]
  def change
    create_table :bdd_tests do |t|
      t.references :project, null: false, foreign_key: true
      t.string :path, null: false
      t.string :name
      t.integer :latest_bdd_test_run_id
      t.integer :latest_status
      t.datetime :latest_run_at

      t.timestamps
    end

    add_index :bdd_tests, [ :project_id, :path ], unique: true
    add_index :bdd_tests, :latest_bdd_test_run_id
  end
end
