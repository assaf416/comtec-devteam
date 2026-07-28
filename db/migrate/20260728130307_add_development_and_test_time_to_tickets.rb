class AddDevelopmentAndTestTimeToTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :tickets, :total_development_time, :decimal, precision: 6, scale: 2
    add_column :tickets, :total_test_time, :decimal, precision: 6, scale: 2
  end
end
