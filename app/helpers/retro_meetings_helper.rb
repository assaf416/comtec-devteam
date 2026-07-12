module RetroMeetingsHelper
  # Renders a 0–100 score as a coloured pill ("—" when not measurable).
  def score_badge(score)
    return content_tag(:span, "—", class: "text-muted") if score.nil?

    cls = if score >= 80 then "bg-success"
    elsif score >= 60 then "bg-warning text-dark"
    else "bg-danger"
    end
    content_tag(:span, "#{score}", class: "badge rounded-pill #{cls}")
  end
end
