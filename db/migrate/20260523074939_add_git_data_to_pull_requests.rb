class AddGitDataToPullRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :pull_requests, :code_changed, :text
    add_column :pull_requests, :test_code, :text
    add_column :pull_requests, :build_errors, :text
    add_column :pull_requests, :latest_test_results, :text
    add_column :pull_requests, :files_changed, :text
    add_column :pull_requests, :pr_comments_data, :text
    add_column :pull_requests, :synced_at, :datetime
  end
end
