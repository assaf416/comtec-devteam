class AddEnvVarsToDeployments < ActiveRecord::Migration[8.1]
  def change
    add_column :deployments, :env_vars, :text
  end
end
