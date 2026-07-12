class AddSprintToDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :documents, :sprint_id, :bigint
    add_index  :documents, :sprint_id
  end
end
