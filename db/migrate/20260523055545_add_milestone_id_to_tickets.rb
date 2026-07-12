class AddMilestoneIdToTickets < ActiveRecord::Migration[8.1]
  def change
    add_reference :tickets, :milestone, null: true, foreign_key: true
  end
end
