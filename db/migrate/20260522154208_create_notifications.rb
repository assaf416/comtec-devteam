class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.string :recipient_type
      t.bigint :recipient_id
      t.string :type
      t.text :params
      t.datetime :read_at

      t.timestamps
    end
  end
end
