class AddServerInfoToDeployments < ActiveRecord::Migration[8.1]
  def change
    add_column :deployments, :server_name,  :string
    add_column :deployments, :server_id,    :string
    add_column :deployments, :server_os,    :string
    add_column :deployments, :ip_address,   :string
    add_column :deployments, :log_file_url, :string
    # Snapshot of the remote machine at deploy time: { cpu, mem, disk, errors }
    add_column :deployments, :os_status,    :text

    add_index :deployments, :ip_address
  end
end
