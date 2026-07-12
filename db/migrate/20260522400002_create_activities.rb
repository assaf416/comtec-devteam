class CreateActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :activities do |t|
      t.references :project,      null: false, foreign_key: true
      t.references :user,         null: false, foreign_key: true
      t.references :subject_user, foreign_key: { to_table: :users }
      t.references :ticket,       foreign_key: true
      t.integer    :event_type,   null: false, default: 9
      t.text       :description,  null: false
      t.text       :metadata

      t.timestamps
    end

    add_index :activities, [ :project_id, :created_at ]
    add_index :activities, :event_type
  end
end
