class AddTicketTypeToCustomerTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :customer_tickets, :ticket_type, :integer, null: false, default: 0
    add_index  :customer_tickets, :ticket_type
  end
end
