class CreateCodeReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :code_reviews do |t|
      t.string  :pr_url,      null: false   # the Gitea PR URL being reviewed
      t.string  :repo_owner
      t.string  :repo_name
      t.integer :pr_number,   null: false
      t.string  :title
      t.string  :author                     # PR author login from Gitea
      t.string  :head_branch
      t.string  :base_branch
      t.string  :gitea_state                # open / closed / merged (from Gitea)
      t.integer :status, null: false, default: 0  # in_review / approved / changes_requested / commented
      t.text    :summary                     # reviewer's overall summary / decision note
      t.bigint  :reviewer_id                 # the user conducting the review
      t.bigint  :project_id                  # resolved from repo_url when possible

      t.timestamps
    end

    add_index :code_reviews, :reviewer_id
    add_index :code_reviews, :project_id
    add_index :code_reviews, :status
    add_index :code_reviews, [ :repo_owner, :repo_name, :pr_number ]
  end
end
