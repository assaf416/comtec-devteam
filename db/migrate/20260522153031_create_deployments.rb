class CreateDeployments < ActiveRecord::Migration[8.1]
  def change
    create_table :deployments do |t|
      t.references :project, null: false, foreign_key: true
      t.string :version
      t.string :environment
      t.references :deployed_by, null: true, foreign_key: { to_table: :users }
      t.datetime :deployed_at
      t.integer :status
      t.string :machine_name
      t.references :client_account, null: true, foreign_key: true
      t.integer :deploy_type
      t.text :notes

      t.timestamps
    end
  end
end
