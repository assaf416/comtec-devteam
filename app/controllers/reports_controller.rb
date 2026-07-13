class ReportsController < ApplicationController
  def ci_summary
    ci_runs_scope = CiRun.includes(:project)

    @total_runs   = ci_runs_scope.count
    @passed_runs  = ci_runs_scope.passed.count
    @failed_runs  = ci_runs_scope.failed.count
    @running_runs = ci_runs_scope.running.count

    @status_breakdown = CiRun.statuses.keys.index_with do |status|
      ci_runs_scope.public_send(status).count
    end.transform_keys(&:humanize)

    @runs_by_day = ci_runs_scope.where(created_at: 30.days.ago..Time.current)
                               .group("DATE(created_at)")
                               .count

    @project_pass_rate = Project.includes(:ci_runs).each_with_object({}) do |project, memo|
      total = project.ci_runs.count
      next if total.zero?

      passed = project.ci_runs.passed.count
      memo[project.name] = ((passed.to_f / total) * 100).round(1)
    end

    @latest_runs = ci_runs_scope.order(created_at: :desc).limit(20)
  end

  def deployment_summary
    deployments_scope = Deployment.includes(:project)

    @total_deployments = deployments_scope.count
    @succeeded_count   = deployments_scope.succeeded.count
    @failed_count      = deployments_scope.failed.count
    @in_progress_count = deployments_scope.in_progress.count

    @status_breakdown = Deployment.statuses.keys.index_with do |status|
      deployments_scope.public_send(status).count
    end.transform_keys(&:humanize)

    @environment_breakdown = deployments_scope.group(:environment).count
    @deploy_type_breakdown = deployments_scope.group(:deploy_type).count.transform_keys(&:humanize)

    @deployments_by_day = deployments_scope.where(created_at: 45.days.ago..Time.current)
                                           .group("DATE(created_at)")
                                           .count

    @deployments_by_project = deployments_scope.joins(:project)
                                              .group("projects.name")
                                              .count

    @recent_deployments = deployments_scope.order(Arel.sql("COALESCE(deployed_at, created_at) DESC"))
                                          .limit(25)
  end

  def test_coverage
    results = TestResult.includes(ci_run: :project).to_a

    @total_suites = results.size
    @total_tests  = results.sum { |r| r.total.to_i }
    @passed_tests = results.sum { |r| r.passed.to_i }
    @failed_tests = results.sum { |r| r.failed.to_i }
    @skipped_tests = results.sum { |r| r.skipped.to_i }

    @overall_pass_rate = percentage(@passed_tests, @total_tests)

    @suite_breakdown = results.group_by { |r| r.suite_name.presence || "Unnamed Suite" }
                              .transform_values do |rows|
      {
        total: rows.sum { |r| r.total.to_i },
        passed: rows.sum { |r| r.passed.to_i },
        failed: rows.sum { |r| r.failed.to_i },
        skipped: rows.sum { |r| r.skipped.to_i }
      }
    end

    @suite_pass_rates = @suite_breakdown.transform_values do |row|
      percentage(row[:passed], row[:total])
    end

    @coverage_trend = Hash.new { |h, k| h[k] = { passed: 0, total: 0 } }
    results.each do |result|
      next unless result.ci_run&.created_at

      day = result.ci_run.created_at.to_date
      @coverage_trend[day][:passed] += result.passed.to_i
      @coverage_trend[day][:total] += result.total.to_i
    end

    @coverage_trend = @coverage_trend.sort_by { |day, _| day }
                                     .last(30)
                                     .to_h
                                     .transform_values { |row| percentage(row[:passed], row[:total]) }
    @recent_results = results.sort_by { |r| -(r.created_at.to_i) }.first(30)
  end

  def estimation_accuracy
    scoped_tickets = Ticket.includes(:project, :estimated_by, :assignee)
                         .where(status: %i[done closed])
                         .where.not(estimated_by_id: nil)
                         .where.not(dev_estimate_hours: nil)
                         .where.not(actual_hours: [ nil, "" ])

    normalized = scoped_tickets.filter_map do |ticket|
      actual_hours = ticket.actual_hours_in_hours
      next if actual_hours.nil?

      estimated_hours = ticket.dev_estimate_hours.to_f
      variance_hours = (actual_hours - estimated_hours).round(2)
      variance_pct = if estimated_hours.positive?
        ((variance_hours / estimated_hours) * 100).round(1)
      else
        nil
      end

      {
        ticket: ticket,
        estimator: ticket.estimated_by,
        estimated_hours: estimated_hours,
        actual_hours: actual_hours,
        variance_hours: variance_hours,
        variance_pct: variance_pct
      }
    end

    @total_evaluated_tickets = normalized.size
    @total_estimated_hours = normalized.sum { |row| row[:estimated_hours] }.round(2)
    @total_actual_hours = normalized.sum { |row| row[:actual_hours] }.round(2)
    @overall_variance_hours = (@total_actual_hours - @total_estimated_hours).round(2)

    grouped = normalized.group_by { |row| row[:estimator] }

    @developer_rows = grouped.map do |estimator, rows|
      estimated_total = rows.sum { |r| r[:estimated_hours] }
      actual_total = rows.sum { |r| r[:actual_hours] }
      variance_total = (actual_total - estimated_total).round(2)
      mean_abs_pct = if rows.any? { |r| r[:variance_pct].present? }
        rows.filter_map { |r| r[:variance_pct]&.abs }.sum / rows.filter_map { |r| r[:variance_pct]&.abs }.size
      else
        0.0
      end

      {
        estimator: estimator,
        tickets_count: rows.count,
        estimated_total: estimated_total.round(2),
        actual_total: actual_total.round(2),
        variance_total: variance_total,
        under_estimated_count: rows.count { |r| r[:variance_hours].positive? },
        over_estimated_count: rows.count { |r| r[:variance_hours].negative? },
        accuracy_score: [ (100.0 - mean_abs_pct).round(1), 0.0 ].max,
        mean_abs_pct: mean_abs_pct.round(1)
      }
    end.sort_by { |row| -row[:tickets_count] }

    @accuracy_by_developer = @developer_rows.to_h { |row| [ row[:estimator].display_name, row[:accuracy_score] ] }
    @variance_by_developer = @developer_rows.to_h { |row| [ row[:estimator].display_name, row[:variance_total] ] }

    @latest_estimation_tickets = normalized.sort_by { |row| -row[:ticket].updated_at.to_i }.first(35)
  end

  private

  def percentage(numerator, denominator)
    return 0.0 if denominator.to_i.zero?

    ((numerator.to_f / denominator.to_f) * 100).round(1)
  end
end
