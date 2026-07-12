class CreateServerHeartbeats < ActiveRecord::Migration[8.1]
  def change
    # Time-series OS telemetry posted by each remote machine's heartbeat agent.
    # A "server" is a distinct ip_address.
    create_table :server_heartbeats do |t|
      t.string   :ip_address,  null: false
      t.string   :server_name
      t.string   :server_os
      t.integer  :cpu                     # % used
      t.integer  :mem                     # % used
      t.integer  :disk                    # % used
      t.integer  :errors,    default: 0   # error count since last beat
      t.string   :log_file_url
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    add_index :server_heartbeats, :ip_address
    add_index :server_heartbeats, [ :ip_address, :recorded_at ]
  end
end
