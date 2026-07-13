class RemoveSprints < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :meetings, :sprints if foreign_key_exists?(:meetings, :sprints)
    remove_foreign_key :tickets,  :sprints if foreign_key_exists?(:tickets, :sprints)

    remove_index  :tickets,           :sprint_id if index_exists?(:tickets, :sprint_id)
    remove_index  :meetings,          :sprint_id if index_exists?(:meetings, :sprint_id)
    remove_index  :documents,         :sprint_id if index_exists?(:documents, :sprint_id)

    remove_column :tickets,           :sprint_id if column_exists?(:tickets, :sprint_id)
    remove_column :meetings,          :sprint_id if column_exists?(:meetings, :sprint_id)
    remove_column :documents,         :sprint_id if column_exists?(:documents, :sprint_id)
    remove_column :ai_chat_sessions,  :sprint_id if column_exists?(:ai_chat_sessions, :sprint_id)

    drop_table :sprints if table_exists?(:sprints)
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Sprints were removed from the product."
  end
end
