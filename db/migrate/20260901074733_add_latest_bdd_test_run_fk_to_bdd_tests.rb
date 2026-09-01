class AddLatestBddTestRunFkToBddTests < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :bdd_tests, :bdd_test_runs, column: :latest_bdd_test_run_id
  end
end
