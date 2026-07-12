class AddActualHoursAndEstimatedByToTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :tickets, :actual_hours, :string
    add_reference :tickets, :estimated_by, foreign_key: { to_table: :users }, index: true
  end
end
