class CreateSprints < ActiveRecord::Migration[8.1]
  def change
    create_table :sprints do |t|
      t.string :name
      t.references :project, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.integer :status
      t.text :goals
      t.integer :velocity

      t.timestamps
    end
  end
end
