class MakeMeetingSprintIdNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :meetings, :sprint_id, true
  end
end
