class CreateMeetings < ActiveRecord::Migration[8.1]
  def change
    create_table :meetings do |t|
      t.string :title
      t.text :description
      t.integer :meeting_type
      t.references :project, null: true, foreign_key: true
      t.datetime :scheduled_at
      t.integer :duration_minutes
      t.string :jitsi_room
      t.string :recording_url
      t.integer :status
      t.text :agenda
      t.text :notes
      t.references :organizer, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
