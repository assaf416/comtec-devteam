require 'rails_helper'

RSpec.describe Project, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe 'associations' do
    it { should have_many(:tickets) }
    it { should have_many(:sprints) }
    it { should have_many(:ci_runs) }
    it { should have_many(:documents) }
    it { should have_many(:deployments) }
    it { should have_many(:meetings) }
  end

  describe 'scopes' do
    it '.active returns only active projects' do
      active = create(:project, active: true)
      inactive = create(:project, active: false)
      expect(Project.active).to include(active)
      expect(Project.active).not_to include(inactive)
    end
  end
end
