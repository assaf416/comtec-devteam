# Stored result of one AI-agent run against the local Ollama LLM.
#
# Every service in Ai:: persists exactly one AiReview so the result is auditable,
# linkable from the UI (AI Reports / Recent Review Results / Recent Test Reviews),
# and replayable. The `reviewable` polymorphic association ties a run back to the
# Ticket / Project it analysed.
class AiReview < ApplicationRecord
  belongs_to :reviewable, polymorphic: true, optional: true
  belongs_to :user, optional: true

  # Keep in sync with the Ai:: service objects and the Tools::AiController actions.
  enum :kind, {
    ticket_quality:      0,   # story-telling / definition-of-ready check
    code_review:         1,   # diff review (Go / Ruby / C# / Node + lint + best practice)
    test_review:         2,   # cucumber test review & missing-coverage suggestions
    estimation_analysis: 3,   # estimated vs actual delivery time
    solution_suggestion: 5,   # read a ticket and suggest an approach
    bug_fix:             6,   # propose a fix for a bug ticket
    task_breakdown:      7,   # break a story into estimated tasks
    status_presentation: 8,   # generate a project status presentation
    spec_document:       9    # generate a specification document
  }, prefix: true

  enum :status, {
    pending:   0,
    running:   1,
    completed: 2,
    failed:    3
  }, prefix: true

  validates :kind, :status, presence: true

  scope :recent,      -> { order(created_at: :desc) }
  scope :code_reviews, -> { where(kind: :code_review) }
  scope :test_reviews, -> { where(kind: :test_review) }
  scope :succeeded,    -> { where(status: :completed) }

  VERDICT_BADGES = {
    "pass"       => "bg-success",
    "needs_work" => "bg-warning",
    "fail"       => "bg-danger"
  }.freeze

  def verdict_badge_class
    VERDICT_BADGES[verdict] || "bg-secondary"
  end

  def title
    case reviewable
    when Ticket  then "T-#{reviewable.id} · #{reviewable.title}"
    when Project then reviewable.name
    else kind.to_s.humanize
    end
  end

  def kind_label
    kind.to_s.humanize
  end

  def duration_seconds
    return nil if duration_ms.blank?
    (duration_ms / 1000.0).round(1)
  end
end
