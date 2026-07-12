require 'rails_helper'

RSpec.describe Ticket, type: :model do
  subject(:ticket) { build(:ticket) }

  # ── Associations ──────────────────────────────────────────────────────────
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:sprint).optional }
  it { is_expected.to belong_to(:assignee).optional }
  it { is_expected.to belong_to(:owner).optional }
  it { is_expected.to belong_to(:estimated_by).optional }
  it { is_expected.to belong_to(:milestone).optional }

  it { is_expected.to have_many(:comments) }
  it { is_expected.to have_many(:branches) }
  it { is_expected.to have_many(:pull_requests) }
  it { is_expected.to have_many(:ci_runs) }
  it { is_expected.to have_many(:ticket_watchers) }

  # ── Validations ───────────────────────────────────────────────────────────
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:project) }

  # ── Enums ─────────────────────────────────────────────────────────────────
  it { is_expected.to define_enum_for(:kind).with_values(story: 0, meta_story: 1, bug_fix: 2, spike: 3, hotfix: 4) }
  it { is_expected.to define_enum_for(:level).with_values(trivial: 0, simple: 1, moderate: 2, complex: 3, expert: 4) }
  it { is_expected.to define_enum_for(:status).with_values(backlog: 0, open: 1, in_progress: 2, in_review: 3, testing: 4, done: 5, closed: 6, blocked: 7) }
  it { is_expected.to define_enum_for(:priority).with_values(low: 0, medium: 1, high: 2, critical: 3) }

  # ── Defaults ──────────────────────────────────────────────────────────────
  describe "defaults" do
    it "defaults status to backlog" do
      expect(Ticket.new.status).to eq("backlog")
    end

    it "defaults priority to medium" do
      expect(Ticket.new.priority).to eq("medium")
    end

    it "defaults kind to story" do
      expect(Ticket.new.kind).to eq("story")
    end
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  describe "#bug_kind?" do
    it "returns true for bug_fix" do
      ticket.kind = :bug_fix
      expect(ticket.bug_kind?).to be true
    end

    it "returns true for hotfix" do
      ticket.kind = :hotfix
      expect(ticket.bug_kind?).to be true
    end

    it "returns false for story" do
      ticket.kind = :story
      expect(ticket.bug_kind?).to be false
    end
  end

  describe "#branch_name_for_ticket" do
    it "returns a feature branch name for story" do
      ticket.kind = :story
      ticket.id   = 42
      ticket.title = "Fix login bug"
      expect(ticket.branch_name_for_ticket).to eq("feature/T-42-fix-login-bug")
    end

    it "returns a bugfix branch name for bug_fix" do
      ticket.kind = :bug_fix
      ticket.id   = 7
      ticket.title = "Crash on login"
      expect(ticket.branch_name_for_ticket).to eq("bugfix/T-7-crash-on-login")
    end
  end

  describe "#actual_hours_in_hours" do
    it "parses day and hour notation" do
      ticket.actual_hours = "2d 4h"
      expect(ticket.actual_hours_in_hours).to eq(20.0)
    end

    it "parses hour-only notation" do
      ticket.actual_hours = "7.5h"
      expect(ticket.actual_hours_in_hours).to eq(7.5)
    end

    it "returns nil for invalid values" do
      ticket.actual_hours = "about tomorrow"
      expect(ticket.actual_hours_in_hours).to be_nil
    end
  end
end
