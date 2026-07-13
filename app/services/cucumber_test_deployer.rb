# Deploys an edited Cucumber (.feature) file to a project's GitHub repository by
# committing it to a fresh branch and opening a pull request for review — never
# writing directly to the default branch. Used by CucumberTestsController#deploy.
class CucumberTestDeployer
  Result = Struct.new(:ok, :pr_url, :branch, :error, keyword_init: true) do
    def ok? = ok
  end

  # Test seam (test env only): when set, #call returns it instead of calling
  # GitHub — mirrors the class-level stubbing used by Ai::OllamaClient etc.
  cattr_accessor :test_result

  def initialize(project:, path:, content:, message: nil, user: nil, github: GithubService.new, now: Time.current)
    @project = project
    @path    = path.to_s.strip
    @content = content.to_s
    @message = message.presence
    @user    = user
    @gh      = github
    @now     = now
  end

  def call
    return self.class.test_result if Rails.env.test? && self.class.test_result

    return failure("This project is not backed by a GitHub repository.") unless github_repo?
    return failure("A file path is required.") if @path.blank?

    owner, repo = GithubService.repo_parts(@project.repo_url)
    return failure("Could not parse the GitHub repo from the project URL.") unless owner && repo

    base = @gh.default_branch(repo_owner: owner, repo_name: repo).presence ||
           @project.default_branch.presence || "main"
    base_sha = @gh.branch_sha(repo_owner: owner, repo_name: repo, branch: base)
    return failure("Could not read the base branch '#{base}' from GitHub.") unless base_sha

    branch = new_branch_name
    unless @gh.create_branch(repo_owner: owner, repo_name: repo, new_branch: branch, from_sha: base_sha)
      return failure("Could not create branch '#{branch}' on GitHub.")
    end

    existing_sha = @gh.content_sha(repo_owner: owner, repo_name: repo, path: @path, ref: branch)
    committed = @gh.put_file(
      repo_owner: owner, repo_name: repo, path: @path,
      content: @content, message: commit_message, branch: branch, sha: existing_sha
    )
    return failure("Could not commit the file to GitHub.") unless committed

    pr = @gh.create_pull_request(
      repo_owner: owner, repo_name: repo,
      title: commit_message, head: branch, base: base, body: pr_body
    )
    return failure("The file was committed but opening the pull request failed.") unless pr

    Result.new(ok: true, pr_url: pr["html_url"], branch: branch)
  end

  private

  def github_repo?
    @project&.repo_url.present? && GithubService.github_url?(@project.repo_url)
  end

  def new_branch_name
    slug = File.basename(@path, ".feature").parameterize.presence || "feature"
    "test/#{slug}-#{@now.strftime('%Y%m%d%H%M%S')}"
  end

  def commit_message
    @message || "Update Cucumber test #{@path}"
  end

  def pr_body
    author = @user&.display_name
    [ "Cucumber test updated via the DevTeam Hub test editor.",
      ("Author: #{author}" if author) ].compact.join("\n\n")
  end

  def failure(message)
    Result.new(ok: false, error: message)
  end
end
