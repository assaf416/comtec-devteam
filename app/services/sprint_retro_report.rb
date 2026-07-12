# Computes the data for a sprint retrospective:
#   • a summary of this sprint (completion, points, task progress, estimation)
#   • a trend comparison against the project's recent sprints
#   • a per-user performance report across three dimensions:
#       story writing quality · estimation accuracy · test quality
#
# Scores are 0–100. Where AI reviews (AiReview) exist they drive the score;
# otherwise a transparent heuristic is used so the report is always populated.
class SprintRetroReport
  Row = Struct.new(:user, :tickets_count, :story_quality, :estimation_accuracy, :test_quality,
                   keyword_init: true) do
    def overall
      vals = [ story_quality, estimation_accuracy, test_quality ].compact
      vals.empty? ? nil : (vals.sum / vals.size).round
    end
  end

  DONE = %w[done closed].freeze

  def initialize(sprint)
    @sprint  = sprint
    @tickets = sprint.tickets.includes(:assignee, :owner, :tasks).to_a
  end

  attr_reader :sprint

  def summary
    total       = @tickets.size
    done        = @tickets.count { |t| DONE.include?(t.status) }
    points_done = @tickets.select { |t| DONE.include?(t.status) }.sum { |t| t.story_points.to_i }
    tasks_total = @tickets.sum { |t| t.tasks_count.to_i }
    tasks_done  = @tickets.sum { |t| t.completed_tasks_count.to_i }

    {
      tickets_total:       total,
      tickets_done:        done,
      completion:          pct(done, total),
      points_planned:      @tickets.sum { |t| t.story_points.to_i },
      points_done:         points_done,
      velocity:            sprint.velocity.presence || points_done,
      tasks_total:         tasks_total,
      tasks_done:          tasks_done,
      task_progress:       pct(tasks_done, tasks_total),
      est_hours:           @tickets.sum { |t| t.total_tasks_estimation.to_f }.round(1),
      estimation_accuracy: estimation_accuracy_for(@tickets)
    }
  end

  # Recent sprints of the project up to and including this one (oldest → newest).
  def trend_sprints
    sprint.project.sprints
          .where(status: %i[active completed])
          .where("end_date <= ?", sprint.end_date)
          .order(:end_date).last(6)
  end

  def velocity_trend
    trend_sprints.to_h { |s| [ s.name, s.velocity.presence || s.tickets.where(status: DONE).count ] }
  end

  def completion_trend
    trend_sprints.to_h do |s|
      total = s.tickets.count
      [ s.name, pct(s.tickets.where(status: DONE).count, total) ]
    end
  end

  def user_rows
    members.map do |user|
      assigned = @tickets.select { |t| t.assignee_id == user.id }
      owned    = @tickets.select { |t| t.owner_id == user.id }
      Row.new(
        user:                user,
        tickets_count:       assigned.size,
        story_quality:       story_quality_for(owned.presence || assigned),
        estimation_accuracy: estimation_accuracy_for(assigned),
        test_quality:        test_quality_for(assigned)
      )
    end.sort_by { |r| -r.tickets_count }
  end

  # Chart-friendly hashes (display_name => score, nils → 0).
  def chart_series
    rows = user_rows
    [
      { name: "Story quality",   data: rows.to_h { |r| [ r.user.display_name, r.story_quality.to_i ] } },
      { name: "Estimation",      data: rows.to_h { |r| [ r.user.display_name, r.estimation_accuracy.to_i ] } },
      { name: "Test quality",    data: rows.to_h { |r| [ r.user.display_name, r.test_quality.to_i ] } }
    ]
  end

  private

  def members
    @sprint.participants.to_a
  end

  def story_quality_for(tickets)
    return nil if tickets.empty?

    ai = ai_scores(:ticket_quality, tickets)
    return avg(ai) if ai.any?

    avg(tickets.map { |t| readiness_score(t) })
  end

  def test_quality_for(tickets)
    return nil if tickets.empty?

    ai = ai_scores(:test_review, tickets)
    return avg(ai) if ai.any?

    pct(tickets.count { |t| t.test_plan.present? }, tickets.size)
  end

  def estimation_accuracy_for(tickets)
    rows = tickets.select do |t|
      DONE.include?(t.status) && t.dev_estimate_hours.present? && t.actual_hours_in_hours.present?
    end
    variances = rows.filter_map do |t|
      est = t.dev_estimate_hours.to_f
      next if est.zero?
      (t.actual_hours_in_hours - est).abs / est * 100
    end
    return nil if variances.empty?

    [ 100 - (variances.sum / variances.size), 0 ].max.round
  end

  # Definition-of-Ready completeness (0–100): description, points, tests, estimate.
  def readiness_score(ticket)
    score = 0
    score += 25 if ticket.description.present?
    score += 25 if ticket.story_points.present?
    score += 25 if ticket.test_plan.present? || ticket.how_to_reproduce.present?
    score += 25 if ticket.dev_estimate_hours.present?
    score
  end

  def ai_scores(kind, tickets)
    AiReview.where(kind: AiReview.kinds[kind], status: AiReview.statuses[:completed],
                   reviewable_type: "Ticket", reviewable_id: tickets.map(&:id))
            .where.not(score: nil).pluck(:score)
  end

  def avg(values)
    return nil if values.empty?
    (values.sum.to_f / values.size).round
  end

  def pct(part, total)
    total.to_i.zero? ? 0 : (part * 100.0 / total).round
  end
end
