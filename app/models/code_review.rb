# An in-app code review of a Gitea pull request, opened by pasting a PR URL.
# Stores the review session + decision; the diff/files/test-results are fetched
# live from Gitea on view. Comments are the polymorphic Comment records, and any
# AI code reviews run against this PR are linked via the polymorphic AiReview.
class CodeReview < ApplicationRecord
  belongs_to :reviewer, class_name: "User", optional: true
  belongs_to :project, optional: true

  has_many :comments,   as: :commentable, dependent: :destroy
  has_many :ai_reviews, as: :reviewable,  dependent: :destroy

  enum :status, {
    in_review:         0,
    approved:          1,
    changes_requested: 2,
    commented:         3
  }, prefix: true

  validates :pr_url, presence: true
  validates :pr_number, presence: true

  scope :recent, -> { order(created_at: :desc) }

  STATUS_BADGES = {
    "in_review"         => "bg-info text-dark",
    "approved"          => "bg-success",
    "changes_requested" => "bg-warning text-dark",
    "commented"         => "bg-secondary"
  }.freeze

  # Parse a Gitea PR URL such as:
  #   http://gitea.local/devteam/print-server/pulls/42
  # Returns { repo_owner:, repo_name:, pr_number: } or nil if it can't be parsed.
  def self.parse_url(url)
    uri  = URI.parse(url.to_s.strip)
    segs = uri.path.to_s.split("/").reject(&:blank?)
    idx  = segs.index("pulls") || segs.index("pull")
    return nil unless idx && idx >= 2 && segs[idx + 1].present?

    {
      repo_owner: segs[idx - 2],
      repo_name:  segs[idx - 1],
      pr_number:  segs[idx + 1].to_i
    }
  rescue URI::InvalidURIError
    nil
  end

  def status_badge_class
    STATUS_BADGES.fetch(status, "bg-secondary")
  end

  def display_title
    title.presence || "PR ##{pr_number}"
  end
end
