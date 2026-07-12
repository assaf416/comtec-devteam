class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :name
      t.text :description
      t.string :repo_url
      t.string :tech_stack
      t.string :gitea_repo_id
      t.string :default_branch
      t.boolean :active

      t.timestamps
    end
  end
end
