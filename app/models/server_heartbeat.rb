# One OS telemetry sample from a remote machine. A "server" is a distinct
# ip_address; the latest heartbeat per ip is its current status.
class ServerHeartbeat < ApplicationRecord
  validates :ip_address, presence: true

  scope :recent,    -> { order(recorded_at: :desc) }
  scope :for_ip,    ->(ip) { where(ip_address: ip) }
  scope :since,     ->(time) { where(recorded_at: time..) }

  # The set of known servers — the latest heartbeat for each ip_address.
  def self.servers
    ids = group(:ip_address).maximum(:recorded_at).map do |ip, ts|
      where(ip_address: ip, recorded_at: ts).limit(1).pick(:id)
    end.compact
    where(id: ids).order(:server_name)
  end

  HEALTHY_THRESHOLDS = { cpu: 85, mem: 90, disk: 90 }.freeze

  def health
    return "error"   if error_count.to_i.positive?
    return "warning" if cpu.to_i >= HEALTHY_THRESHOLDS[:cpu] ||
                        mem.to_i >= HEALTHY_THRESHOLDS[:mem] ||
                        disk.to_i >= HEALTHY_THRESHOLDS[:disk]
    "ok"
  end

  def health_badge_class
    { "ok" => "bg-success", "warning" => "bg-warning text-dark", "error" => "bg-danger" }[health]
  end
end
