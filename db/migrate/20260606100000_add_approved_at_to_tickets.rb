class AddApprovedAtToTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :tickets, :approved_at, :datetime
  end
end
