require 'rails_helper'

RSpec.describe CustomerTicket, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
  end

  describe 'associations' do
    it { should belong_to(:customer) }
    it { should belong_to(:assigned_to).optional }
    it { should belong_to(:internal_ticket).optional }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(open: 0, in_progress: 1, waiting_for_customer: 2, resolved: 3, closed: 4).with_prefix }
    it { should define_enum_for(:priority).with_values(low: 0, medium: 1, high: 2, critical: 3).with_prefix }
  end

  describe '#resolve!' do
    it 'sets status to resolved and records resolved_at' do
      ct = create(:customer_ticket, status: :open)
      ct.resolve!
      expect(ct.reload.status).to eq("resolved")
      expect(ct.resolved_at).to be_present
    end
  end

  describe '#link_to_internal!' do
    it 'links to an internal ticket' do
      project = create(:project)
      internal = create(:ticket, project: project)
      ct = create(:customer_ticket)
      ct.link_to_internal!(internal)
      expect(ct.reload.internal_ticket).to eq(internal)
    end
  end

  describe 'scopes' do
    it '.open_tickets returns open, in_progress, waiting tickets' do
      open_ct     = create(:customer_ticket, status: :open)
      resolved_ct = create(:resolved_customer_ticket)
      expect(CustomerTicket.open_tickets).to include(open_ct)
      expect(CustomerTicket.open_tickets).not_to include(resolved_ct)
    end

    it '.high_priority returns high and critical' do
      critical = create(:critical_customer_ticket)
      low      = create(:customer_ticket, priority: :low)
      expect(CustomerTicket.high_priority).to include(critical)
      expect(CustomerTicket.high_priority).not_to include(low)
    end
  end
end
