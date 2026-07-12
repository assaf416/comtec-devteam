class CreateCustomerUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :customer_users do |t|
      t.references :customer, null: false, foreign_key: true

      t.string :name,  null: false
      t.string :email, null: false, default: ""

      ## Database authenticatable
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      t.timestamps null: false
    end

    add_index :customer_users, :email,                unique: true
    add_index :customer_users, :reset_password_token, unique: true
  end
end
