class AddActualVelocityToTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :tickets, :actual_velocity, :integer
  end
end
