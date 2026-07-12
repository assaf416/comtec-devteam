class AddTemplateFieldsToDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :documents, :is_template, :boolean, default: false, null: false
    add_column :documents, :template_id, :integer
    add_index  :documents, :is_template
    add_index  :documents, :template_id
  end
end
