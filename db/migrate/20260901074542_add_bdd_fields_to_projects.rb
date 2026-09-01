class AddBddFieldsToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :home_folder, :string
    add_column :projects, :cucumber_cmd, :string
    add_column :projects, :project_kind, :integer, default: 0, null: false
  end
end
