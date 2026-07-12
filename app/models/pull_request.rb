class PullRequest < ApplicationRecord
  belongs_to :project
  belongs_to :ticket, optional: true

  has_many :comments, as: :commentable

  serialize :files_changed,       coder: JSON
  serialize :pr_comments_data,    coder: JSON
  serialize :latest_test_results, coder: JSON
  serialize :files_data,          coder: JSON   # [{ path, url, language, status, additions, deletions, content }]
  serialize :tests_data,          coder: JSON   # [{ name, file, suite, status, time_ms }]

  enum :status, { open: 0, review: 1, merged: 2, closed: 3 }, default: :open

  validates :title, presence: true
  validates :pr_number, presence: true

  EXT_LANGUAGE = {
    ".rb" => "ruby", ".rake" => "ruby", ".go" => "go", ".cs" => "csharp", ".vb" => "vbnet",
    ".js" => "javascript", ".ts" => "typescript", ".jsx" => "javascript", ".tsx" => "typescript",
    ".vue" => "vue", ".py" => "python", ".java" => "java", ".feature" => "gherkin",
    ".html" => "html", ".erb" => "erb", ".css" => "css", ".scss" => "scss",
    ".json" => "json", ".yml" => "yaml", ".yaml" => "yaml", ".md" => "markdown", ".sql" => "sql"
  }.freeze

  def pr_comments
    Array(pr_comments_data)
  end

  # Rich file list (preferred); falls back to plain changed filenames.
  def pr_files
    files = Array(files_data)
    return files if files.any?

    changed_files.map { |f| { "path" => f, "language" => self.class.language_for(f) } }
  end

  def feature_files
    pr_files.select { |f| f["path"].to_s.end_with?(".feature") }
  end

  def pr_tests
    Array(tests_data)
  end

  def test_summary
    tests = pr_tests
    return latest_test_results if tests.empty? && latest_test_results.is_a?(Hash)

    {
      "total"   => tests.size,
      "passed"  => tests.count { |t| t["status"] == "passed" },
      "failed"  => tests.count { |t| t["status"] == "failed" },
      "skipped" => tests.count { |t| t["status"] == "skipped" }
    }
  end

  def changed_files
    files = Array(files_data)
    return files.map { |f| f["path"] } if files.any?

    Array(files_changed)
  end

  def synced?
    synced_at.present?
  end

  def test_files
    changed_files.select { |f| f.to_s.match?(/spec|test|_test\.|_spec\.|\.feature\z/) }
  end

  def source_files
    changed_files - test_files
  end

  def self.language_for(path)
    EXT_LANGUAGE.fetch(File.extname(path.to_s), "text")
  end
end
