class Attachment < ApplicationRecord
  belongs_to :project
  belongs_to :uploaded_by, class_name: "User", optional: true
  belongs_to :attachable, polymorphic: true, optional: true

  has_one_attached :file

  has_many :attachment_views, dependent: :destroy

  # Same spirit as Ticket::ALLOWED_ATTACHMENT_TYPES, extended for the file
  # repository: images, video, any text/* (Markdown, plain, CSV, HTML), Office
  # documents (Word/Excel) and PDF. Other application/* types are rejected.
  ALLOWED_APPLICATION_TYPES = %w[
    application/csv
    application/pdf
    application/msword
    application/vnd.ms-excel
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/octet-stream
  ].freeze

  MAX_EXTRACTED_TEXT = 200_000

  enum :extraction_status, {
    pending: 0, done: 1, failed: 2, unsupported: 3
  }, default: :pending

  validates :file, presence: true
  validate  :acceptable_file

  before_validation :default_title, on: :create
  after_create_commit :enqueue_extraction

  scope :recent, -> { order(updated_at: :desc) }

  # Content search over title + extracted document text. Parameterized LIKE keeps
  # the existing SQLite-dev / Postgres-prod convention (see AllDocumentsController).
  scope :search, ->(query) {
    q = "%#{query}%"
    where("attachments.title LIKE :q OR attachments.extracted_text LIKE :q", q: q)
  }

  def filename
    file.attached? ? file.filename.to_s : nil
  end

  def content_type
    file.attached? ? file.blob.content_type.to_s : nil
  end

  def byte_size
    file.attached? ? file.blob.byte_size : 0
  end

  private

  def default_title
    self.title = file.filename.to_s if title.blank? && file.attached?
  end

  def enqueue_extraction
    ExtractAttachmentTextJob.perform_later(id)
  end

  def acceptable_file
    return unless file.attached?

    ct = file.blob&.content_type.to_s
    return if ct.start_with?("image/", "video/", "text/")
    return if ALLOWED_APPLICATION_TYPES.include?(ct)

    errors.add(:file,
               "#{file.filename} is an unsupported type (#{ct.presence || 'unknown'}). " \
               "Allowed: images, video, text/Markdown/CSV/HTML, Word, Excel, PDF.")
  end
end
