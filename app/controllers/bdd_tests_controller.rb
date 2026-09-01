# Browse, import, and run Cucumber suites belonging to OTHER (possibly
# non-Ruby) projects checked out on this machine — see
# app/services/bdd_test_import_service.rb for the import mechanism and
# app/jobs/bdd_test_run_job.rb for execution. Distinct from Test Studio
# (app/controllers/test_studio_controller.rb), which only runs this app's own
# internal suite.
class BddTestsController < ApplicationController
  before_action :require_admin_or_qa!, only: %i[run run_selected import edit update]

  def index
    @tests = BddTest.includes(:project, :latest_bdd_test_run).order(:project_id, :path)
    @selected_tag = params[:tag].presence
    @tests = @tests.tagged_with(@selected_tag) if @selected_tag
    @selected_project_id = params[:project_id].presence
    @tests = @tests.where(project_id: @selected_project_id) if @selected_project_id
    @query = params[:q].presence
    if @query
      like = "%#{@query}%"
      @tests = @tests.where("bdd_tests.name LIKE :q OR bdd_tests.path LIKE :q", q: like)
    end
    @tag_counts = BddTest.tag_counts_on(:tags)
    @tests_by_project = @tests.group_by(&:project)
    @projects = Project.order(:name)
  end

  def show
    @bdd_test = BddTest.find(params[:id])
    @runs = @bdd_test.bdd_test_runs.order(id: :desc).limit(20)
  end

  def edit
    @bdd_test = BddTest.find(params[:id])
    unless @bdd_test.safe_path?
      redirect_to bdd_tests_path, alert: t("bdd_tests.unsafe_path")
      return
    end

    @content = File.read(@bdd_test.absolute_path)
    @rtl = hebrew?(@content)
  end

  def update
    @bdd_test = BddTest.find(params[:id])
    unless @bdd_test.safe_path?
      redirect_to bdd_tests_path, alert: t("bdd_tests.unsafe_path")
      return
    end

    File.write(@bdd_test.absolute_path, params[:content].to_s)
    redirect_to edit_bdd_test_path(@bdd_test), notice: t("bdd_tests.saved")
  end

  def run
    bdd_test = BddTest.find(params[:id])
    enqueue_run(bdd_test)
    redirect_back fallback_location: bdd_tests_path
  end

  def run_selected
    BddTest.where(id: Array(params[:bdd_test_ids])).find_each { |bdd_test| enqueue_run(bdd_test) }
    redirect_to bdd_tests_path
  end

  def import
    project = Project.find(params[:project_id])
    result = BddTestImportService.new(project).call
    notice = t("bdd_tests.imported", count: result.imported_count)
    notice = "#{notice} (#{result.pull_warning})" if result.pull_warning.present?
    redirect_to bdd_tests_path, notice: notice
  end

  private

  def enqueue_run(bdd_test)
    run = BddTestRun.create!(bdd_test: bdd_test, status: :queued, triggered_by: current_user)
    BddTestRunJob.perform_later(run.id)
    run
  end

  def hebrew?(content)
    content.each_line.find { |l| l.strip.present? }.to_s.strip == "# language: he"
  end

  def require_admin_or_qa!
    return if current_user&.admin? || current_user&.qa?

    redirect_to bdd_tests_path, alert: t("bdd_tests.not_authorized")
  end
end
