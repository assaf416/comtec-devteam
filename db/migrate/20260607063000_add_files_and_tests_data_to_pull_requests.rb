class AddFilesAndTestsDataToPullRequests < ActiveRecord::Migration[8.1]
  def change
    # Rich per-file data: [{ path, url, language, status, additions, deletions, content }]
    add_column :pull_requests, :files_data, :text
    # Structured test results: [{ name, file, suite, status, time_ms }]
    add_column :pull_requests, :tests_data, :text
    add_column :pull_requests, :coverage_percent, :decimal, precision: 5, scale: 2
  end
end
