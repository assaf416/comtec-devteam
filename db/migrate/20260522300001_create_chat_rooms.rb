class CreateChatRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_rooms do |t|
      t.string  :name,        null: false
      t.text    :description
      t.integer :room_type,   null: false, default: 0
      t.references :project,  foreign_key: true
      t.boolean :archived,    null: false, default: false

      t.timestamps
    end

    add_index :chat_rooms, :name, unique: true
  end
end
