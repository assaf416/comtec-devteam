class CreateBranches < ActiveRecord::Migration[8.1]
  def change
    create_table :branches do |t|
      t.string :name
      t.references :project, null: false, foreign_key: true
      t.references :ticket, null: false, foreign_key: true
      t.integer :status
      t.datetime :created_at_gitea

      t.timestamps
    end
  end
end
