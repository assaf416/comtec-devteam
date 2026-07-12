class CreateMilestones < ActiveRecord::Migration[8.1]
  def change
    create_table :milestones do |t|
      t.string :name
      t.text :description
      t.references :project, null: false, foreign_key: true
      t.date :due_date
      t.integer :status

      t.timestamps
    end
  end
end
