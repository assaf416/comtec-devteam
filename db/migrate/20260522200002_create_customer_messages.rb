class CreateCustomerMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :customer_messages do |t|
      t.references :customer, null: false, foreign_key: true

      # polymorphic sender: CustomerUser (portal) or User (internal team)
      t.string  :sender_type, null: false
      t.bigint  :sender_id,   null: false

      t.string  :subject
      t.text    :body,          null: false
      t.boolean :internal_only, null: false, default: false

      t.timestamps null: false
    end

    add_index :customer_messages, %i[sender_type sender_id], name: "index_customer_messages_on_sender"
  end
end
