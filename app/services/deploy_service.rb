# Orchestrates a deploy: it figures out which CI image tags can be deployed,
# creates the Deployment record, hands the actual rollout to the external
# backend (Deploy::JarvisClient), and reflects the result back on the record.
#
# When the backend isn't configured/reachable the deployment is recorded as
# :pending with an explanatory note, so the console works end-to-end in a demo.
class DeployService
  Tag = Struct.new(:tag, :label, :commit, :branch, :built_at, :ci_run_id, keyword_init: true)

  def initialize(client: Deploy::JarvisClient.new)
    @client = client
  end

  def backend_configured? = @client.configured?
  def backend_available?  = @client.available?

  # Deployable image tags for a project. Prefer the backend's list; fall back to
  # this app's own passing CI runs (build_number => image tag).
  def deployable_tags(project, limit: 25)
    from_backend = @client.available_tags(project_ref: project_ref(project)).map do |img|
      Tag.new(tag: img["tag"], label: img["tag"], commit: img["commit"], built_at: img["built_at"])
    end
    return from_backend if from_backend.any?

    project.ci_runs.where(status: :passed).order(created_at: :desc).limit(limit).map do |run|
      Tag.new(
        tag:       run.build_number,
        label:     "#{run.build_number} · #{run.commit_sha.to_s.first(7)} (#{run.branch_name})",
        commit:    run.commit_sha,
        branch:    run.branch_name,
        built_at:  run.finished_at || run.created_at,
        ci_run_id: run.id
      )
    end
  end

  # Create the Deployment row and trigger the backend. Returns the Deployment.
  def deploy!(project:, image_tag:, environment:, server:, user:)
    deployment = project.deployments.build(
      version:      image_tag,
      environment:  environment,
      deploy_type:  :docker,
      status:       :pending,
      deployed_by:  user,
      deployed_at:  Time.current,
      server_name:  server&.server_name,
      server_id:    server && "srv-#{server.ip_address.to_s.split('.').last}",
      server_os:    server&.server_os,
      ip_address:   server&.ip_address,
      notes:        "Triggered from the Deploy console by #{user&.display_name}."
    )
    return deployment unless deployment.save

    begin
      @client.deploy(
        project_ref:  project_ref(project),
        image_tag:    image_tag,
        environment:  environment,
        server_ip:    server&.ip_address,
        triggered_by: user&.email
      )
      deployment.update(status: :in_progress)
    rescue Deploy::JarvisClient::Error => e
      # Backend not wired up yet — keep the record queued and surface why.
      deployment.update(status: :pending, notes: "#{deployment.notes} (Queued — #{e.message})")
    end

    deployment
  end

  # Stable identifier the backend uses for a project. Name-based, URL-safe.
  def project_ref(project)
    project.name.to_s.parameterize
  end
end
