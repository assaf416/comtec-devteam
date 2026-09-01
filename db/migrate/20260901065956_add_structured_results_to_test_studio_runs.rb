class AddStructuredResultsToTestStudioRuns < ActiveRecord::Migration[8.1]
  def change
    add_column :test_studio_runs, :structured_results, :text
  end
end
