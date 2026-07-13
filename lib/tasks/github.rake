namespace :github do
  desc "Sync GitHub issues into tickets for all projects (or one via project_id=ID). " \
       "Pass replace=1 to wipe local tickets first."
  task sync: :environment do
    replace = ENV["replace"].to_s == "1" || ENV["REPLACE"].to_s == "1"
    scope   = ENV["project_id"].present? ? Project.where(id: ENV["project_id"]) : Project.all

    projects = scope.select { |p| GithubService.github_url?(p.repo_url) }
    if projects.empty?
      puts "No projects with a github.com repo_url found. Set project.repo_url to a GitHub URL."
      next
    end

    projects.each do |project|
      print "Syncing #{project.name} (#{project.repo_url})… "
      result = GithubIssueSyncService.new(project, replace: replace).call
      if result.ok?
        puts "imported #{result.imported}, updated #{result.updated}, removed #{result.removed}, skipped #{result.skipped}"
      else
        puts "ERROR: #{result.error}"
      end
    end
  end
end
