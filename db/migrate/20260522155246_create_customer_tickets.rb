class CreateCustomerTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :customer_tickets do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body
      t.integer :status, null: false, default: 0
      t.integer :priority, null: false, default: 1
      t.references :assigned_to, null: true, foreign_key: { to_table: :users }
      t.references :internal_ticket, null: true, foreign_key: { to_table: :tickets }
      t.datetime :resolved_at

      t.timestamps
    end
  end
end
