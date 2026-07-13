class AddGithubIssueFields < ActiveRecord::Migration[8.1]
  def change
    add_column :tickets, :github_issue_number, :integer
    add_column :tickets, :github_url,          :string
    add_column :tickets, :github_state,        :string
    add_column :tickets, :github_synced_at,    :datetime

    add_index :tickets, [ :project_id, :github_issue_number ],
              unique: true,
              where: "github_issue_number IS NOT NULL",
              name: "index_tickets_on_project_and_github_issue"

    # GitHub login → local User, so synced issue assignees map to real people.
    add_column :users, :github_login, :string
    add_index  :users, :github_login
  end
end
