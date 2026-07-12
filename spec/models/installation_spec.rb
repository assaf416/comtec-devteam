require 'rails_helper'

RSpec.describe Installation, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:software_name) }
    it { should validate_presence_of(:version) }
    it { should validate_presence_of(:environment) }
    it { should validate_inclusion_of(:environment).in_array(Installation::ENVIRONMENTS) }
  end

  describe 'associations' do
    it { should belong_to(:customer) }
    it { should belong_to(:project).optional }
    it { should belong_to(:deployment).optional }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(active: 0, pending: 1, outdated: 2, decommissioned: 3, failed: 4).with_prefix }
  end

  describe 'auto-outdating previous installations' do
    it 'marks the previous active installation as outdated when a new one is created' do
      customer  = create(:customer)
      old_inst  = create(:installation, customer: customer, software_name: "TDI2", version: "1.0", status: :active)
      _new_inst = create(:installation, customer: customer, software_name: "TDI2", version: "2.0", status: :active)
      expect(old_inst.reload.status).to eq("outdated")
    end

    it 'does not affect installations of different software' do
      customer      = create(:customer)
      other_install = create(:installation, customer: customer, software_name: "Print Server", version: "5.0", status: :active)
      _new_inst     = create(:installation, customer: customer, software_name: "TDI2", version: "2.0", status: :active)
      expect(other_install.reload.status).to eq("active")
    end
  end

  describe 'scopes' do
    it '.active returns only active status' do
      active   = create(:installation, status: :active)
      outdated = create(:outdated_installation)
      expect(Installation.active).to include(active)
      expect(Installation.active).not_to include(outdated)
    end

    it '.for_env filters by environment' do
      prod    = create(:installation, environment: "production")
      staging = create(:installation, environment: "staging")
      expect(Installation.for_env("production")).to include(prod)
      expect(Installation.for_env("production")).not_to include(staging)
    end
  end
end
