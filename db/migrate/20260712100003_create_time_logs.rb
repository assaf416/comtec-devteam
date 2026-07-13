class CreateTimeLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :time_logs do |t|
      t.references :user,    null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.references :ticket,  null: true,  foreign_key: true
      t.decimal :hours, precision: 6, scale: 2, null: false, default: "0.0"
      t.date    :spent_on, null: false
      t.text    :note
      t.timestamps
    end

    add_index :time_logs, [ :user_id, :spent_on ]
    add_index :time_logs, [ :project_id, :spent_on ]
  end
end
