class AddTestPlanToTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :tickets, :test_plan, :text
  end
end
