class Project < ApplicationRecord
  has_many :milestones
  has_many :tickets
  has_many :time_logs, dependent: :destroy
  has_many :ci_runs
  has_many :deployments
  has_many :documents
  has_many :meetings
  has_many :pull_requests
  has_many :branches
  has_many :installations
  has_many :project_memberships, dependent: :destroy
  has_many :members, through: :project_memberships, source: :user
  has_many :activities, dependent: :destroy
  has_many :ai_reviews, as: :reviewable, dependent: :destroy
  has_many :chat_rooms, dependent: :nullify
  has_many :attachments, dependent: :destroy

  validates :name, presence: true

  scope :active, -> { where(active: true) }

  after_create :create_default_documents

  # Standard documents auto-created for every new project
  DEFAULT_DOCUMENTS = [
    { doc_type: :risk_management, title: "Risk Management",
      content: "# Risk Management\n\n## Risks\n\n| Risk | Likelihood | Impact | Mitigation |\n|------|-----------|--------|------------|\n| TBD  | -          | -      | -          |\n" },
    { doc_type: :user_story,      title: "Product Backlog",
      content: "# Product Backlog\n\n## Epics\n\n_List epics here._\n\n## Stories\n\n_List user stories here._\n" },
    { doc_type: :test_coverage,   title: "Test Plan",
      content: "# Test Plan\n\n## Scope\n\n_Describe what will be tested._\n\n## Test Cases\n\n| ID | Description | Steps | Expected | Status |\n|----|-------------|-------|----------|--------|\n" }
  ].freeze

  private

  def create_default_documents
    DEFAULT_DOCUMENTS.each do |attrs|
      documents.create!(
        title:    "#{attrs[:title]} — #{name}",
        doc_type: attrs[:doc_type],
        content:  attrs[:content]
      )
    end
  end
end
