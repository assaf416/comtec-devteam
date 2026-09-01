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
  has_many :bdd_tests, dependent: :destroy

  enum :project_kind, { application: 0, test_suite: 1 }, default: :application

  validates :name, presence: true

  scope :active, -> { where(active: true) }

  after_create :create_default_documents

  # Standard documents auto-created for every new project
  DEFAULT_DOCUMENTS = [
    { doc_type: :risk_management, title: "ניהול סיכונים",
      content: "# ניהול סיכונים\n\n## סיכונים\n\n| סיכון | סבירות | השפעה | פתרון |\n|------|-----------|--------|------------|\n| טרם הוגדר | -          | -      | -          |\n" },
    { doc_type: :user_story,      title: "בקלוג מוצר",
      content: "# בקלוג מוצר\n\n## אפיקים (Epics)\n\n_רשימת אפיקים כאן._\n\n## סיפורי משתמש\n\n_רשימת סיפורי משתמש כאן._\n" },
    { doc_type: :test_coverage,   title: "תוכנית בדיקות",
      content: "# תוכנית בדיקות\n\n## היקף\n\n_תיאור מה ייבדק._\n\n## מקרי בדיקה\n\n| מזהה | תיאור | שלבים | תוצאה צפויה | סטטוס |\n|----|-------------|-------|----------|--------|\n" }
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
