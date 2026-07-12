module TicketsHelper
  # Render a number of hours without a trailing ".0" (e.g. 12.0 → "12", 4.5 → "4.5").
  def hours_label(value)
    n = value.to_f
    (n % 1).zero? ? n.to_i.to_s : n.round(1).to_s
  end

  # Emoji icon for an attachment based on its content type.
  def attachment_icon(content_type)
    ct = content_type.to_s
    return "🖼️" if ct.start_with?("image/")
    return "🎬" if ct.start_with?("video/")
    return "📊" if ct.include?("csv") || ct.include?("excel") || ct.include?("spreadsheet")
    return "📕" if ct == "application/pdf"
    "📎"
  end
end
