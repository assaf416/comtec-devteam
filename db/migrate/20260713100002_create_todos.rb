class CreateTodos < ActiveRecord::Migration[8.1]
  def change
    create_table :todo_lists do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.timestamps
    end

    create_table :todo_items do |t|
      t.references :todo_list, null: false, foreign_key: true
      t.string  :content, null: false
      t.boolean :done, null: false, default: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :todo_items, [ :todo_list_id, :position ]
  end
end
