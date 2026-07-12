class CreateTicketWatchers < ActiveRecord::Migration[8.1]
  def change
    create_table :ticket_watchers do |t|
      t.references :ticket, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
