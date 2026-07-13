class CreateNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :notes do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :title
      t.text    :body
      t.boolean :pinned,   null: false, default: false
      t.boolean :archived, null: false, default: false
      t.timestamps
    end

    add_index :notes, [ :user_id, :archived, :pinned ]
  end
end
