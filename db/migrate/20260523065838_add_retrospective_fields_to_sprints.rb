class AddRetrospectiveFieldsToSprints < ActiveRecord::Migration[8.1]
  def change
    add_column :sprints, :things_to_improve, :text
    add_column :sprints, :things_that_went_right, :text
  end
end
