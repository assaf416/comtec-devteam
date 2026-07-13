require "pdf-reader"
require "docx"
require "roo"

# Reads an uploaded file's textual content and stores it on the Attachment as
# `extracted_text`, so files become searchable by their contents. Images (and
# any format we can't read as text) are marked :unsupported. Runs async after an
# attachment is created (Attachment#enqueue_extraction).
class ExtractAttachmentTextJob < ApplicationJob
  queue_as :default

  def perform(attachment_id)
    attachment = Attachment.find_by(id: attachment_id)
    return unless attachment&.file&.attached?

    text = extract_text(attachment)

    if text.nil?
      attachment.update!(extraction_status: :unsupported,
                         extracted_text: attachment.filename)
    else
      attachment.update!(extraction_status: :done,
                         extracted_text: text.to_s.strip.first(Attachment::MAX_EXTRACTED_TEXT))
    end
  rescue => e
    Rails.logger.warn "ExtractAttachmentTextJob failed for ##{attachment_id}: #{e.class}: #{e.message}"
    attachment&.update_columns(extraction_status: Attachment.extraction_statuses[:failed])
  end

  private

  # Returns extracted text, or nil when the format is unsupported (e.g. images).
  def extract_text(attachment)
    ct   = attachment.content_type.to_s
    name = attachment.filename.to_s.downcase

    return read_html(attachment)  if ct == "text/html" || name.end_with?(".html", ".htm")
    return read_plain(attachment) if ct.start_with?("text/") || name.end_with?(".md", ".markdown", ".txt", ".csv")
    return read_pdf(attachment)   if ct == "application/pdf" || name.end_with?(".pdf")
    return read_docx(attachment)  if name.end_with?(".docx") || ct == "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    return read_xlsx(attachment)  if name.end_with?(".xlsx", ".xls") || ct.include?("excel") || ct.include?("spreadsheet")

    nil
  end

  def read_plain(attachment)
    attachment.file.download.to_s.force_encoding("UTF-8").scrub
  end

  def read_html(attachment)
    ActionController::Base.helpers.strip_tags(read_plain(attachment))
  end

  def read_pdf(attachment)
    io = StringIO.new(attachment.file.download)
    PDF::Reader.new(io).pages.map(&:text).join("\n")
  end

  def read_docx(attachment)
    with_tempfile(attachment, ".docx") do |path|
      Docx::Document.open(path).paragraphs.map(&:text).join("\n")
    end
  end

  def read_xlsx(attachment)
    ext = File.extname(attachment.filename.to_s).delete(".").downcase
    ext = "xlsx" unless %w[xlsx xls csv].include?(ext)
    with_tempfile(attachment, ".#{ext}") do |path|
      sheet = Roo::Spreadsheet.open(path, extension: ext.to_sym)
      sheet.sheets.flat_map { |s| sheet.sheet(s).to_a }
           .flatten.compact.map(&:to_s).reject(&:blank?).join(" ")
    end
  end

  # Some parsers need a real file path rather than an in-memory blob.
  def with_tempfile(attachment, suffix)
    Tempfile.create([ "attachment", suffix ]) do |tmp|
      tmp.binmode
      tmp.write(attachment.file.download)
      tmp.flush
      yield tmp.path
    end
  end
end
