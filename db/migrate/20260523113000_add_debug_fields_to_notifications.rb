class AddDebugFieldsToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :message, :text
    add_column :notifications, :error_message, :text
    add_column :notifications, :backtrace, :text
  end
end
