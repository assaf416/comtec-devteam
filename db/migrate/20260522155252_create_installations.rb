class CreateInstallations < ActiveRecord::Migration[8.1]
  def change
    create_table :installations do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :project, null: true, foreign_key: true
      t.references :deployment, null: true, foreign_key: true
      t.string :software_name, null: false
      t.string :version, null: false
      t.string :environment, null: false, default: 'production'
      t.datetime :installed_at
      t.text :notes
      t.integer :status, null: false, default: 0

      t.timestamps
    end
    add_index :installations, [ :customer_id, :software_name ]
    add_index :installations, :status
  end
end
