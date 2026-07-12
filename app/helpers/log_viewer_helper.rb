module LogViewerHelper
  # Row CSS class — drives the colour highlight for errors / warnings / exceptions.
  def log_row_class(entry)
    classes = [ "log-line" ]
    classes << "log-#{entry[:level]}" if LogQueryService::LEVELS.include?(entry[:level])
    classes << "log-exception" if entry[:exception]
    classes.join(" ")
  end

  def log_level_badge_class(level)
    {
      "error" => "bg-danger",
      "warn"  => "bg-warning text-dark",
      "info"  => "bg-info text-dark",
      "debug" => "bg-secondary"
    }.fetch(level, "bg-light text-dark")
  end

  # Renders the message, highlighting the active search term when present.
  def log_message(entry, search)
    msg = entry[:message]
    return msg if search.blank?

    highlight(msg, search, highlighter: '<mark>\1</mark>')
  end
end
