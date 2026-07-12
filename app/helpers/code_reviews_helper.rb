module CodeReviewsHelper
  # CSS class for one line of a unified diff.
  def diff_line_class(line)
    case line
    when /\Adiff --git/, /\Aindex /, /\A--- /, /\A\+\+\+ /, /\A@@/ then "diff-meta"
    when /\A\+/ then "diff-add"
    when /\A-/  then "diff-del"
    else "diff-ctx"
    end
  end

  # Badge colour for a Gitea changed-file status.
  def file_status_class(status)
    {
      "added"    => "bg-success",
      "modified" => "bg-info text-dark",
      "deleted"  => "bg-danger",
      "renamed"  => "bg-warning text-dark"
    }.fetch(status.to_s, "bg-secondary")
  end

  # Badge colour for a Gitea commit-status state.
  def commit_status_class(state)
    {
      "success" => "bg-success",
      "pending" => "bg-warning text-dark",
      "failure" => "bg-danger",
      "error"   => "bg-danger"
    }.fetch(state.to_s, "bg-secondary")
  end
end
