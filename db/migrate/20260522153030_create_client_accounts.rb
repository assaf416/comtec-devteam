class CreateClientAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :client_accounts do |t|
      t.string :name
      t.string :email
      t.string :contact_name
      t.string :contact_phone
      t.text :notes

      t.timestamps
    end
  end
end
