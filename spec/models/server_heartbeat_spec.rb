require 'rails_helper'

RSpec.describe ServerHeartbeat, type: :model do
  def beat(ip, at, **attrs)
    ServerHeartbeat.create!(ip_address: ip, recorded_at: at, **attrs)
  end

  describe ".servers" do
    it "returns the latest heartbeat per distinct ip_address" do
      beat("10.0.0.1", 2.hours.ago, server_name: "old", cpu: 10)
      latest1 = beat("10.0.0.1", 1.minute.ago, server_name: "new", cpu: 80)
      latest2 = beat("10.0.0.2", 5.minutes.ago, server_name: "other", cpu: 40)

      servers = ServerHeartbeat.servers
      expect(servers.map(&:ip_address)).to contain_exactly("10.0.0.1", "10.0.0.2")
      expect(servers.find { |s| s.ip_address == "10.0.0.1" }.id).to eq(latest1.id)
      expect(servers.find { |s| s.ip_address == "10.0.0.2" }.id).to eq(latest2.id)
    end
  end

  describe "#health" do
    it "is error when there are errors" do
      expect(beat("1.1.1.1", Time.current, cpu: 5, mem: 5, disk: 5, error_count: 2).health).to eq("error")
    end

    it "is warning when a resource is high" do
      expect(beat("1.1.1.2", Time.current, cpu: 95, mem: 5, disk: 5, error_count: 0).health).to eq("warning")
    end

    it "is ok otherwise" do
      expect(beat("1.1.1.3", Time.current, cpu: 20, mem: 30, disk: 40, error_count: 0).health).to eq("ok")
    end
  end
end
