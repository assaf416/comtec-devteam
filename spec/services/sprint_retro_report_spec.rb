require 'rails_helper'

RSpec.describe SprintRetroReport do
  let(:project) { create(:project) }
  let(:sprint)  { create(:sprint, project: project, velocity: 20) }
  let(:dev)     { create(:user, name: "Dev One") }

  describe "#summary" do
    it "summarizes completion and points" do
      create(:ticket, project: project, sprint: sprint, status: :done, story_points: 5)
      create(:ticket, project: project, sprint: sprint, status: :open, story_points: 3)
      s = described_class.new(sprint.reload).summary
      expect(s[:tickets_total]).to eq(2)
      expect(s[:tickets_done]).to eq(1)
      expect(s[:completion]).to eq(50)
      expect(s[:points_done]).to eq(5)
    end
  end

  describe "#user_rows scoring" do
    it "scores estimation accuracy from est vs actual on done tickets" do
      create(:ticket, project: project, sprint: sprint, assignee: dev, owner: dev,
             status: :done, dev_estimate_hours: 10, actual_hours: "10h")
      create(:ticket, project: project, sprint: sprint, assignee: dev, owner: dev,
             status: :done, dev_estimate_hours: 10, actual_hours: "15h")
      row = described_class.new(sprint.reload).user_rows.find { |r| r.user == dev }
      expect(row.estimation_accuracy).to eq(75) # mean abs variance 25% → 100-25
    end

    it "scores story quality from definition-of-ready completeness (no AI reviews)" do
      create(:ticket, project: project, sprint: sprint, owner: dev, assignee: dev,
             description: "x", story_points: 3, test_plan: "t", dev_estimate_hours: 4)
      row = described_class.new(sprint.reload).user_rows.find { |r| r.user == dev }
      expect(row.story_quality).to eq(100)
    end

    it "scores test quality from test_plan coverage" do
      create(:ticket, project: project, sprint: sprint, assignee: dev, owner: dev, test_plan: "has")
      create(:ticket, project: project, sprint: sprint, assignee: dev, owner: dev, test_plan: nil)
      row = described_class.new(sprint.reload).user_rows.find { |r| r.user == dev }
      expect(row.test_quality).to eq(50)
    end

    it "prefers AI ticket_quality scores when present" do
      t = create(:ticket, project: project, sprint: sprint, owner: dev, assignee: dev)
      create(:ai_review, reviewable: t, kind: :ticket_quality, status: :completed, score: 90)
      row = described_class.new(sprint.reload).user_rows.find { |r| r.user == dev }
      expect(row.story_quality).to eq(90)
    end
  end

  describe "#chart_series and trends" do
    it "produces three named series and trend hashes" do
      create(:ticket, project: project, sprint: sprint, assignee: dev, owner: dev)
      report = described_class.new(sprint.reload)
      expect(report.chart_series.map { |s| s[:name] }).to eq([ "Story quality", "Estimation", "Test quality" ])
      expect(report.velocity_trend).to be_a(Hash)
      expect(report.completion_trend).to be_a(Hash)
    end
  end
end
