class CreateChatRoomPins < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_room_pins do |t|
      t.references :user, null: false, foreign_key: true
      t.references :chat_room, null: false, foreign_key: true
      t.datetime :pinned_at, null: false

      t.timestamps
    end

    add_index :chat_room_pins, [ :user_id, :chat_room_id ], unique: true
  end
end
