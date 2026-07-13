module AttachmentsHelper
  # Emoji file-type icon based on an attachment's filename + content type.
  # Emoji (not bi-* / font-awesome) is used because Bootstrap Icons is not
  # actually installed in this app — emoji renders reliably everywhere.
  def attachment_type_icon(attachment)
    name = attachment.filename.to_s.downcase
    ct   = attachment.content_type.to_s

    return "🖼️" if ct.start_with?("image/")
    return "🎬" if ct.start_with?("video/")
    return "📕" if ct == "application/pdf" || name.end_with?(".pdf")
    return "📘" if name.end_with?(".doc", ".docx") || ct.include?("word")
    return "📊" if name.end_with?(".xls", ".xlsx", ".csv") ||
                   ct.include?("excel") || ct.include?("spreadsheet") || ct.include?("csv")
    return "📝" if name.end_with?(".md", ".markdown")
    return "🌐" if ct == "text/html" || name.end_with?(".html", ".htm")
    return "📄" if ct.start_with?("text/")

    "📎"
  end

  # Human-readable file size (e.g. "1.2 MB").
  def attachment_size(attachment)
    number_to_human_size(attachment.byte_size)
  end

  # Small badge describing content-extraction state.
  def attachment_status_badge(attachment)
    color = {
      "done" => "success", "pending" => "secondary",
      "failed" => "danger", "unsupported" => "light"
    }[attachment.extraction_status] || "secondary"
    content_tag :span, attachment.extraction_status.humanize,
                class: "badge bg-#{color} text-dark is-light is-small"
  end
end
