# Jenkins API integration service
class JenkinsService
  BASE_URL = ENV.fetch("JENKINS_URL", "http://localhost:8080")
  USER = ENV.fetch("JENKINS_USER", "admin")
  TOKEN = ENV.fetch("JENKINS_TOKEN", "")

  def initialize
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.request  :json
      f.response :json
      f.request :authorization, :basic, USER, TOKEN
    end
  end

  # Fetch recent builds for a job
  def builds(job_name:, limit: 10)
    response = @conn.get("/job/#{job_name}/api/json", { tree: "builds[number,result,timestamp,duration,url]{0,#{limit}}" })
    response.success? ? response.body.dig("builds") || [] : []
  rescue Faraday::Error => e
    Rails.logger.error "JenkinsService#builds failed: #{e.message}"
    []
  end

  # Trigger a build with optional parameters
  def trigger_build(job_name:, params: {})
    path = params.any? ? "/job/#{job_name}/buildWithParameters" : "/job/#{job_name}/build"
    response = @conn.post(path) do |req|
      req.params = params if params.any?
    end
    response.success?
  rescue Faraday::Error => e
    Rails.logger.error "JenkinsService#trigger_build failed: #{e.message}"
    false
  end

  # Get test report for a build
  def test_report(job_name:, build_number:)
    response = @conn.get("/job/#{job_name}/#{build_number}/testReport/api/json")
    response.success? ? response.body : nil
  rescue Faraday::Error
    nil
  end

  # Sync a Jenkins build into a CiRun record
  def self.sync_build(project:, job_name:, build_data:)
    build_number = build_data["number"].to_s
    ci_run = CiRun.find_or_initialize_by(project: project, build_number: build_number)
    ci_run.status = case build_data["result"]
    when "SUCCESS"  then :passed
    when "FAILURE"  then :failed
    when "ABORTED"  then :cancelled
    else :running
    end
    ci_run.started_at  = Time.at(build_data["timestamp"].to_i / 1000) if build_data["timestamp"]
    ci_run.log_url     = "#{BASE_URL}/job/#{job_name}/#{build_number}/console"
    ci_run.save
    ci_run
  end
end
