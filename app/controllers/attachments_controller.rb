class AttachmentsController < ApplicationController
  before_action :set_project,    only: %i[new create]
  before_action :set_attachment, only: %i[show destroy]

  # Browse + search files. Scoped to a project when nested, otherwise across all.
  def index
    scope = Attachment.includes(:project, :uploaded_by, file_attachment: :blob)
    scope = scope.where(project_id: params[:project_id]) if params[:project_id].present?
    scope = scope.search(params[:q]) if params[:q].present?

    @project     = Project.find(params[:project_id]) if params[:project_id].present?
    @attachments = scope.recent.limit(200)
    @grouped     = @attachments.group_by(&:project)
  end

  def new
    @attachment = @project.attachments.new
  end

  # Quick multi-file upload: one Attachment record per uploaded file.
  def create
    files = Array(params.dig(:attachment, :files)).reject(&:blank?)
    return redirect_to(new_project_attachment_path(@project), alert: t("attachments.none_selected")) if files.empty?

    created = files.map do |file|
      attachment = @project.attachments.new(attachment_meta_params)
      attachment.uploaded_by = current_user
      attachment.file.attach(file)
      attachment.save
    end

    if created.all?
      redirect_to project_attachments_path(@project),
                  notice: t("attachments.uploaded", count: created.size)
    else
      redirect_to new_project_attachment_path(@project),
                  alert: t("attachments.upload_failed")
    end
  end

  def show
    AttachmentView.record(user: current_user, attachment: @attachment)
    respond_to do |format|
      format.html
      format.any { redirect_to rails_blob_path(@attachment.file, disposition: "inline") }
    end
  end

  def destroy
    project = @attachment.project
    @attachment.destroy
    redirect_to project_attachments_path(project), notice: t("attachments.deleted")
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_attachment
    @attachment = Attachment.includes(:project, :uploaded_by, file_attachment: :blob).find(params[:id])
  end

  def attachment_meta_params
    params.fetch(:attachment, {}).permit(:title, :attachable_type, :attachable_id)
  end
end
