class Deployment < ApplicationRecord
  belongs_to :project
  belongs_to :deployed_by, class_name: "User", optional: true
  belongs_to :client_account, optional: true
  has_many :installations

  serialize :env_vars, coder: JSON
  serialize :os_status, coder: JSON   # snapshot at deploy time: { cpu, mem, disk, errors }

  enum :status, { pending: 0, in_progress: 1, succeeded: 2, failed: 3, rolled_back: 4 }, default: :pending
  enum :deploy_type, { web_app: 0, windows_installer: 1, windows_service: 2, docker: 3 }, default: :web_app

  validates :version, :environment, presence: true

  def env_vars_hash
    Array(env_vars).each_with_object({}) { |row, h| h[row["key"]] = row["value"] if row["key"].present? }
  end

  def os_status_hash
    os_status.is_a?(Hash) ? os_status : {}
  end

  # Latest live heartbeat for this deployment's server (by ip_address).
  def latest_heartbeat
    return nil if ip_address.blank?
    ServerHeartbeat.for_ip(ip_address).recent.first
  end
end
