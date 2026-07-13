module Api
  module V1
    # Token-authenticated attachment API. Lets the AI agent (and CLI/extension)
    # upload files programmatically; the extraction job runs automatically so the
    # content becomes searchable.
    class AttachmentsController < BaseController
      before_action :set_attachment, only: %i[show]

      def index
        scope = Attachment.includes(:project, :uploaded_by, file_attachment: :blob)
        scope = scope.where(project_id: params[:project_id]) if params[:project_id].present?
        scope = scope.search(params[:q]) if params[:q].present?

        attachments = scope.recent.limit(100)
        render json: attachments.map { |attachment| render_attachment(attachment) }
      end

      def show
        render json: render_attachment(@attachment)
      end

      # POST /api/v1/attachments  (multipart/form-data)
      #   project_id (required), file (required),
      #   title, attachable_type, attachable_id (optional)
      def create
        project = Project.find_by(id: params[:project_id])
        return render json: { error: "Project not found" }, status: :not_found unless project

        file = params[:file]
        return render json: { error: "file is required" }, status: :unprocessable_entity if file.blank?

        attachment = project.attachments.new(
          title:           params[:title],
          attachable_type: params[:attachable_type],
          attachable_id:   params[:attachable_id],
          uploaded_by:     current_api_user
        )
        attachment.file.attach(file)

        if attachment.save
          render json: render_attachment(attachment), status: :created
        else
          render json: { errors: attachment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_attachment
        @attachment = Attachment.includes(:project, file_attachment: :blob).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Attachment not found" }, status: :not_found
      end
    end
  end
end
