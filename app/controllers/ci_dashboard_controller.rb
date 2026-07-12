class CiDashboardController < ApplicationController
  def index
    @stats = {
      total:    CiRun.count,
      passed:   CiRun.passed.count,
      failed:   CiRun.failed.count,
      running:  CiRun.running.count
    }

    @test_stats = begin
      total  = TestResult.sum(:total)
      passed = TestResult.sum(:passed)
      rate   = total > 0 ? ((passed.to_f / total) * 100).round(1) : 0
      { total: total, passed: passed, failed: TestResult.sum(:failed), pass_rate: rate }
    end

    @recent_failures = CiRun.failed
                             .includes(:project, :triggered_by)
                             .order(created_at: :desc)
                             .limit(5)

    @project_health = Project.active.order(:name).map do |project|
      runs  = project.ci_runs.order(created_at: :desc).limit(10)
      total = runs.count
      next nil if total.zero?

      passed = runs.passed.count
      latest = runs.first
      { project: project, pass_rate: ((passed.to_f / total) * 100).round(0), latest: latest }
    end.compact

    @deployments_by_env = Deployment.group(:environment).count
    @recent_deployments = Deployment.includes(:project, :deployed_by)
                                    .where.not(status: :pending)
                                    .order(Arel.sql("COALESCE(deployed_at, created_at) DESC"))
                                    .limit(6)
  end

  def runs
    @projects = Project.active.order(:name)

    scope = CiRun.includes(:project, :triggered_by, :test_results, :ticket)
    scope = scope.where(project_id: params[:project_id]) if params[:project_id].present?
    scope = scope.where(status: params[:status])         if params[:status].present?
    scope = scope.where("branch_name LIKE ?", "%#{params[:branch]}%") if params[:branch].present?

    @ci_runs = scope.order(created_at: :desc).page(params[:page]).per(30)
  end

  def security
    @projects = Project.active.order(:name)

    # Deterministic simulated Trivy-style findings per project
    # Based on tech_stack text to generate realistic CVE lists
    @findings = @projects.map { |p| build_security_findings(p) }

    @critical_total = @findings.sum { |f| f[:critical].size }
    @high_total     = @findings.sum { |f| f[:high].size }
    @medium_total   = @findings.sum { |f| f[:medium].size }
    @low_total      = @findings.sum { |f| f[:low].size }
  end

  def performance
    @projects = Project.active.order(:name)

    # Build duration trend from actual CI run data
    @duration_by_project = @projects.map do |project|
      runs = project.ci_runs
                    .where.not(started_at: nil, finished_at: nil)
                    .order(started_at: :asc)
                    .last(10)
      durations = runs.map(&:duration).compact
      avg = durations.any? ? (durations.sum / durations.size).round(1) : nil
      { project: project, runs: runs, avg_duration: avg }
    end

    # Test suite execution times
    @slow_suites = TestResult.joins(:ci_run)
                             .includes(ci_run: :project)
                             .order(duration_ms: :desc)
                             .limit(10)

    @duration_trend = CiRun.where.not(started_at: nil, finished_at: nil)
                            .order(started_at: :asc)
                            .last(20)
                            .map { |r| [ r.started_at.strftime("%d/%m"), r.duration ] }
                            .to_h
  end

  private

  SECURITY_CVE_POOL = {
    critical: [
      { cve: "CVE-2024-21626", pkg: "runc",          ver: "1.1.11",   fix: "1.1.12",   desc: "Container breakout via file descriptor leak" },
      { cve: "CVE-2024-3094",  pkg: "xz-utils",      ver: "5.6.0",    fix: "5.4.6",    desc: "Supply chain backdoor in liblzma" },
      { cve: "CVE-2023-44487", pkg: "nghttp2",        ver: "1.57.0",   fix: "1.58.0",   desc: "HTTP/2 Rapid Reset DoS" },
      { cve: "CVE-2024-6387",  pkg: "openssh-server", ver: "9.7p1",    fix: "9.8p1",    desc: "Remote code execution (regreSSHion)" }
    ],
    high: [
      { cve: "CVE-2024-22025", pkg: "node",           ver: "20.10.0",  fix: "20.12.0",  desc: "Path traversal in import.meta.resolve()" },
      { cve: "CVE-2024-27980", pkg: "node",           ver: "20.11.1",  fix: "20.12.2",  desc: "Command injection in child_process on Windows" },
      { cve: "CVE-2024-38428", pkg: "wget",           ver: "1.21.3",   fix: "1.21.4",   desc: "URL redirect with credential exposure" },
      { cve: "CVE-2023-5363",  pkg: "openssl",        ver: "3.1.3",    fix: "3.1.4",    desc: "AES-SIV key/IV confusion issue" },
      { cve: "CVE-2024-4741",  pkg: "openssl",        ver: "3.2.1",    fix: "3.2.2",    desc: "Use-after-free in SSL_free_buffers" }
    ],
    medium: [
      { cve: "CVE-2024-29415", pkg: "ip",             ver: "2.0.0",    fix: "2.0.1",    desc: "SSRF bypass via IPv6 loopback" },
      { cve: "CVE-2024-28863", pkg: "node-tar",       ver: "6.2.0",    fix: "6.2.1",    desc: "DoS via malformed headers in tar extraction" },
      { cve: "CVE-2023-52425", pkg: "expat",          ver: "2.5.0",    fix: "2.6.0",    desc: "DoS via XML entity expansion" },
      { cve: "CVE-2024-2961",  pkg: "glibc",          ver: "2.39",     fix: "2.39-r1",  desc: "Buffer overflow in ISO-2022-CN-EXT codec" }
    ],
    low: [
      { cve: "CVE-2024-35325", pkg: "libyaml",        ver: "0.2.5",    fix: "0.2.5-r3", desc: "Out-of-bounds read in yaml_parser_parse" },
      { cve: "CVE-2024-26130", pkg: "cryptography",   ver: "41.0.7",   fix: "42.0.4",   desc: "NULL pointer dereference in PKCS12 handling" }
    ]
  }.freeze

  def build_security_findings(project)
    # Use project id as seed for deterministic "random" selection
    seed = project.id.to_i
    {
      project:  project,
      critical: SECURITY_CVE_POOL[:critical].select.with_index { |_, i| (seed + i) % 3 == 0 },
      high:     SECURITY_CVE_POOL[:high].select.with_index    { |_, i| (seed + i) % 2 == 0 },
      medium:   SECURITY_CVE_POOL[:medium].select.with_index  { |_, i| (seed + i) % 2 != 0 },
      low:      SECURITY_CVE_POOL[:low],
      scanned_at: Time.current - ((seed % 5) + 1).hours,
      image:    project.name.parameterize + ":latest"
    }
  end
end
