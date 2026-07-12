require 'rails_helper'

RSpec.describe Sprint, type: :model do
  describe "validations" do
    subject { build(:sprint) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }

    it "is invalid when end_date is before start_date" do
      sprint = build(:sprint, start_date: Date.today, end_date: Date.today - 1)
      expect(sprint).not_to be_valid
      expect(sprint.errors[:end_date]).to include("must be after start date")
    end

    it "is valid when end_date equals start_date" do
      sprint = build(:sprint, start_date: Date.today, end_date: Date.today)
      expect(sprint).to be_valid
    end
  end

  describe "associations" do
    it { should belong_to(:project) }
    it { should have_many(:tickets) }
    it { should have_many(:meetings) }
    it { should have_many(:pull_requests).through(:tickets) }
    it { should have_many(:comments) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_values(planning: 0, active: 1, completed: 2, cancelled: 3) }
  end

  describe "scopes" do
    it ".active returns only active sprints" do
      active    = create(:active_sprint)
      planning  = create(:sprint, status: :planning)
      expect(Sprint.active).to include(active)
      expect(Sprint.active).not_to include(planning)
    end

    it ".current returns active sprints whose date range includes today" do
      current  = create(:active_sprint, start_date: Date.today - 1, end_date: Date.today + 5)
      future   = create(:active_sprint, start_date: Date.today + 10, end_date: Date.today + 24)
      expect(Sprint.current).to include(current)
      expect(Sprint.current).not_to include(future)
    end

    it ".upcoming returns only future sprints, earliest first" do
      current  = create(:active_sprint, start_date: Date.today - 1, end_date: Date.today + 5)
      soon     = create(:sprint, start_date: Date.today + 7,  end_date: Date.today + 21)
      later    = create(:sprint, start_date: Date.today + 30, end_date: Date.today + 44)
      expect(Sprint.upcoming).to eq([ soon, later ])
      expect(Sprint.upcoming).not_to include(current)
    end
  end

  describe "#progress_percent" do
    it "returns 0 when there are no tickets" do
      sprint = create(:sprint)
      expect(sprint.progress_percent).to eq(0)
    end

    it "calculates percentage of done + closed tickets" do
      project = create(:project)
      sprint  = create(:sprint, project: project)
      create(:ticket, project: project, sprint: sprint, status: :done)
      create(:ticket, project: project, sprint: sprint, status: :done)
      create(:ticket, project: project, sprint: sprint, status: :open)
      expect(sprint.progress_percent).to eq(67)
    end
  end

  describe "#days_remaining" do
    it "returns days until end_date for an active sprint" do
      sprint = build(:active_sprint, end_date: Date.today + 5)
      expect(sprint.days_remaining).to eq(5)
    end

    it "returns 0 for an overdue sprint" do
      sprint = build(:sprint, end_date: Date.today - 3)
      expect(sprint.days_remaining).to eq(0)
    end
  end

  describe "#duration_days" do
    it "calculates the number of days between start and end" do
      sprint = build(:sprint, start_date: Date.today, end_date: Date.today + 14)
      expect(sprint.duration_days).to eq(14)
    end
  end

  describe "estimated / actual hour totals" do
    let(:project) { create(:project) }
    let(:sprint)  { create(:sprint, project: project) }

    it "sums dev + QA estimates and actual hours across tickets" do
      create(:ticket, project: project, sprint: sprint, dev_estimate_hours: 8, tester_estimate_hours: 2, actual_hours: "1d 2h") # 10h
      create(:ticket, project: project, sprint: sprint, dev_estimate_hours: 4, actual_hours: "3h")
      expect(sprint.total_estimated_hours).to eq(14.0)
      expect(sprint.total_actual_hours).to eq(13.0)
    end

    it "is zero with no tickets" do
      expect(sprint.total_estimated_hours).to eq(0)
      expect(sprint.total_actual_hours).to eq(0)
    end
  end
end
