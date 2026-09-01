require "open3"
require "gherkin"

# Imports .feature files from a Project's home_folder into BddTest records:
# best-effort `git pull` to sync the checkout, then a glob + Gherkin parse for
# each file to cache its name and populate tags (used for fast filtering).
# Idempotent — safe to re-run (matches this app's db/seeds.rb find_or_create_by!
# convention).
class BddTestImportService
  Result = Struct.new(:imported_count, :pull_warning, keyword_init: true)

  def initialize(project)
    @project = project
  end

  def call
    return Result.new(imported_count: 0, pull_warning: "home_folder is blank") if @project.home_folder.blank?

    pull_warning = best_effort_git_pull
    imported = 0

    Dir.glob(File.join(@project.home_folder, "**", "*.feature")).each do |absolute_path|
      relative_path = absolute_path.delete_prefix("#{File.expand_path(@project.home_folder)}/")
      import_one(relative_path, absolute_path)
      imported += 1
    end

    Result.new(imported_count: imported, pull_warning: pull_warning)
  end

  private

  # Mirrors TicketBranchService's convention: never raise, just log and
  # report a warning string the caller can surface to the user.
  def best_effort_git_pull
    return nil unless File.directory?(File.join(@project.home_folder, ".git"))

    output, status = Open3.capture2e("git", "-C", @project.home_folder, "pull", "--ff-only")
    return nil if status.success?

    Rails.logger.warn("[BddTestImportService] git pull failed for #{@project.name}: #{output}")
    "git pull failed: #{output.lines.first&.strip}"
  rescue StandardError => e
    Rails.logger.warn("[BddTestImportService] git pull error for #{@project.name}: #{e.message}")
    "git pull error: #{e.message}"
  end

  def import_one(relative_path, absolute_path)
    document = Gherkin::Parser.new.parse(StringIO.new(File.read(absolute_path)))
    feature  = document.feature

    bdd_test = BddTest.find_or_create_by!(project: @project, path: relative_path)
    bdd_test.name = feature&.name.presence || File.basename(relative_path, ".feature")
    bdd_test.tag_list = feature_tags(feature)
    bdd_test.save!
  rescue StandardError => e
    Rails.logger.warn("[BddTestImportService] could not parse #{relative_path}: #{e.message}")
  end

  def feature_tags(feature)
    return [] unless feature

    tags = feature.tags.to_a
    feature.children.each do |child|
      tags += child.scenario.tags.to_a if child.scenario
    end
    tags.map { |t| t.name.delete_prefix("@") }.uniq
  end
end
