class AddBlockedToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :blocked, :boolean, null: false, default: false
  end
end
