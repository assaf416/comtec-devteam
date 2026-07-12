require 'rails_helper'

RSpec.describe Customer, type: :model do
  describe 'validations' do
    subject { build(:customer) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
  end

  describe 'associations' do
    it { should have_many(:customer_tickets).dependent(:destroy) }
    it { should have_many(:installations).dependent(:destroy) }
  end

  describe 'scopes' do
    it '.active returns only active customers' do
      active   = create(:customer, active: true)
      inactive = create(:customer, active: false)
      expect(Customer.active).to include(active)
      expect(Customer.active).not_to include(inactive)
    end
  end

  describe '#display_name' do
    it 'includes company in parentheses when present' do
      c = build(:customer, name: "Jane Doe", company: "ACME")
      expect(c.display_name).to eq("Jane Doe (ACME)")
    end

    it 'returns just name when company is blank' do
      c = build(:customer, name: "Jane Doe", company: nil)
      expect(c.display_name).to eq("Jane Doe")
    end
  end
end
