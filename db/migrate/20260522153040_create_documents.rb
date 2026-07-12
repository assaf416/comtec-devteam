class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.string :title
      t.text :content
      t.integer :doc_type
      t.references :project, null: false, foreign_key: true
      t.references :author, null: true, foreign_key: { to_table: :users }
      t.text :summary
      t.string :version_number

      t.timestamps
    end
  end
end
