class DefaultUsersToHebrew < ActiveRecord::Migration[8.1]
  def up
    change_column_default :users, :preferred_language, "he"
    # Existing users without an explicit language become Hebrew.
    execute "UPDATE users SET preferred_language = 'he' WHERE preferred_language IS NULL OR preferred_language = ''"
  end

  def down
    change_column_default :users, :preferred_language, nil
  end
end
