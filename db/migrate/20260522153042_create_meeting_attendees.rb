class CreateMeetingAttendees < ActiveRecord::Migration[8.1]
  def change
    create_table :meeting_attendees do |t|
      t.references :meeting, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :attended

      t.timestamps
    end
  end
end
