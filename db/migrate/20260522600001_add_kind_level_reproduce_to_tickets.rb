class AddKindLevelReproduceToTickets < ActiveRecord::Migration[8.0]
  def change
    # Replace ticket_type column with kind (new enum values: story/meta_story/bug_fix/spike/hotfix)
    rename_column :tickets, :ticket_type, :kind

    add_column :tickets, :how_to_reproduce, :text
    add_column :tickets, :level, :integer, null: false, default: 2  # 2 = moderate

    add_index :tickets, :level
    # index on :kind already exists (renamed from index_tickets_on_ticket_type)
  end
end
