class AddEstimationAndOwnerToTickets < ActiveRecord::Migration[8.0]
  def change
    add_column :tickets, :ticket_type,           :integer, null: false, default: 0
    add_column :tickets, :dev_estimate_hours,    :decimal, precision: 6, scale: 2
    add_column :tickets, :tester_estimate_hours, :decimal, precision: 6, scale: 2
    add_column :tickets, :owner_id,              :bigint
    add_column :tickets, :pr_url,                :string

    add_foreign_key :tickets, :users, column: :owner_id
    add_index :tickets, :owner_id
    add_index :tickets, :ticket_type
  end
end
