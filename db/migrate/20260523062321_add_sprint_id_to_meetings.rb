class AddSprintIdToMeetings < ActiveRecord::Migration[8.1]
  def change
    add_reference :meetings, :sprint, null: true, foreign_key: true
  end
end
