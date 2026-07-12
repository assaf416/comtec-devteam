class Document < ApplicationRecord
  belongs_to :project
  belongs_to :sprint, optional: true
  belongs_to :author, class_name: "User", optional: true
  belongs_to :template, class_name: "Document", optional: true
  has_many :generated_documents, class_name: "Document", foreign_key: :template_id, dependent: :nullify

  has_many :comments, as: :commentable
  has_one_attached :attachment

  acts_as_taggable_on :tags

  enum :doc_type, {
    spec: 0, risk_management: 1, user_story: 2, timeline: 3,
    test_coverage: 4, architecture: 5, runbook: 6, other: 7,
    presentation: 8
  }, default: :other

  scope :templates, -> { where(is_template: true) }
  scope :regular,   -> { where(is_template: false) }

  validates :title, :content, presence: true

  def template_badge
    is_template? ? "Template" : nil
  end

  def duplicate_from_template(new_title: nil)
    dup.tap do |d|
      d.title       = new_title || "#{title} (copy)"
      d.is_template = false
      d.template_id = id
      d.version_number = "1.0"
    end
  end
end
