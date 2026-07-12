class CreateChatMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_messages do |t|
      t.references :chat_room, null: false, foreign_key: true
      t.references :user,      null: false, foreign_key: true
      t.text   :body,      null: false
      t.text   :rich_refs
      t.datetime :edited_at

      t.timestamps
    end

    add_index :chat_messages, [ :chat_room_id, :created_at ]
  end
end
