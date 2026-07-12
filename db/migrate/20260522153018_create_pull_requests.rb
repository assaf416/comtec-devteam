class CreatePullRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :pull_requests do |t|
      t.string :title
      t.text :description
      t.integer :status
      t.references :project, null: false, foreign_key: true
      t.references :ticket, null: false, foreign_key: true
      t.integer :pr_number
      t.string :author
      t.string :gitea_url
      t.datetime :merged_at

      t.timestamps
    end
  end
end
