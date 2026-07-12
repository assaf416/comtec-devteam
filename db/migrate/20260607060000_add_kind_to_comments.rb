class AddKindToComments < ActiveRecord::Migration[8.1]
  def change
    # note / red_card / green_card — surfaced especially on the sprint page.
    add_column :comments, :kind, :integer, default: 0, null: false
  end
end
