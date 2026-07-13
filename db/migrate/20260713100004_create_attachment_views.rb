class CreateAttachmentViews < ActiveRecord::Migration[8.1]
  def change
    create_table :attachment_views do |t|
      t.references :user, null: false, foreign_key: true
      t.references :attachment, null: false, foreign_key: true
      t.datetime :viewed_at, null: false
      t.timestamps
    end

    add_index :attachment_views, [ :user_id, :attachment_id ], unique: true
    add_index :attachment_views, [ :user_id, :viewed_at ]
  end
end
