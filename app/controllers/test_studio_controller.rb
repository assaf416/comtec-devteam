# Browse, edit, and run this app's own Hebrew Cucumber suite (features/*.feature)
# from the browser instead of the terminal. See app/models/test_studio_run.rb
# for the run-history model and app/jobs/test_studio_run_job.rb for execution.
class TestStudioController < ApplicationController
  FEATURES_ROOT = Rails.root.join("features")

  def index
    paths = feature_paths
    @entries = paths.map { |path| { path: path, hebrew: hebrew_file?(path), group: group_for(path) } }
    @groups = @entries.map { |e| e[:group] }.uniq.sort
    @selected_group = params[:group].presence
    @entries = @entries.select { |e| e[:group] == @selected_group } if @selected_group
    @runs_by_path = latest_runs_by_path(paths)
  end

  def edit
    @path = safe_feature_path(params[:path])
    return redirect_to(test_studio_path) unless @path

    @content = File.read(FEATURES_ROOT.join(@path))
    @rtl = hebrew?(@content)
    @run = TestStudioRun.where(feature_path: @path).order(:id).last
  end

  def update
    path = safe_feature_path(params[:path])
    return redirect_to(test_studio_path) unless path

    File.write(FEATURES_ROOT.join(path), params[:content].to_s)
    redirect_to edit_test_studio_test_path(path: path), notice: t("test_studio.saved")
  end

  def run
    path = safe_feature_path(params[:path])
    return redirect_to(test_studio_path) unless path

    enqueue_run(path)
    redirect_to(params[:return_to] == "edit" ? edit_test_studio_test_path(path: path) : test_studio_path)
  end

  def run_all
    group = params[:group].presence
    paths = feature_paths
    paths = paths.select { |path| group_for(path) == group } if group
    paths.each { |path| enqueue_run(path) }
    redirect_to test_studio_path(group: group)
  end

  def run_selected
    Array(params[:paths]).filter_map { |raw| safe_feature_path(raw) }.each { |path| enqueue_run(path) }
    redirect_to test_studio_path
  end

  private

  def feature_paths
    Dir.glob(FEATURES_ROOT.join("**/*.feature")).map { |f| Pathname.new(f).relative_path_from(FEATURES_ROOT).to_s }.sort
  end

  def latest_runs_by_path(paths)
    latest_ids = TestStudioRun.where(feature_path: paths).group(:feature_path).maximum(:id).values
    TestStudioRun.where(id: latest_ids).index_by(&:feature_path)
  end

  def enqueue_run(path)
    run = TestStudioRun.create!(feature_path: path, status: :queued, triggered_by: current_user)
    TestStudioRunJob.perform_later(run.id)
    run
  end

  def hebrew?(content)
    content.each_line.find { |l| l.strip.present? }.to_s.strip == "# language: he"
  end

  def hebrew_file?(path)
    first_line = File.foreach(FEATURES_ROOT.join(path)).find { |l| l.strip.present? }
    first_line.to_s.strip == "# language: he"
  end

  # Lightweight stand-in for "project" grouping: feature files aren't tied to
  # a Project record, so we group by the naming convention already used
  # throughout features/ (the part of the filename before the first "_",
  # e.g. "admin_user_management.feature" → "admin").
  def group_for(path)
    File.basename(path, ".feature").split("_").first
  end

  # Resolves the given relative path against FEATURES_ROOT and requires it to
  # stay inside it and end in .feature — prevents path traversal / arbitrary
  # file reads or writes via the path param.
  def safe_feature_path(raw)
    return nil if raw.blank?

    full = File.expand_path(FEATURES_ROOT.join(raw.to_s))
    return nil unless full.start_with?("#{FEATURES_ROOT}/")
    return nil unless full.end_with?(".feature")
    return nil unless File.exist?(full)

    Pathname.new(full).relative_path_from(FEATURES_ROOT).to_s
  end
end
