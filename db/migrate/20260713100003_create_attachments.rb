class CreateAttachments < ActiveRecord::Migration[8.1]
  def change
    create_table :attachments do |t|
      t.references :project, null: false, foreign_key: true
      t.references :uploaded_by, foreign_key: { to_table: :users }
      t.references :attachable, polymorphic: true
      t.string  :title
      t.text    :extracted_text
      t.integer :extraction_status, null: false, default: 0
      t.timestamps
    end
  end
end
