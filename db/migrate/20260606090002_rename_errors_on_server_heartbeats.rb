class RenameErrorsOnServerHeartbeats < ActiveRecord::Migration[8.1]
  def change
    # `errors` collides with ActiveModel's #errors — use error_count instead.
    rename_column :server_heartbeats, :errors, :error_count
  end
end
