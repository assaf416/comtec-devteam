module CustomerPortal
  class DocumentsController < BaseController
    VISIBLE_TYPES = %w[spec architecture runbook user_story timeline other].freeze

    before_action :set_document, only: %i[show]

    def index
      project_ids = current_customer.installations.pluck(:project_id).compact.uniq
      @type_filter = params[:doc_type].presence_in(VISIBLE_TYPES)

      @documents = Document.where(project_id: project_ids)
                     .where(doc_type: VISIBLE_TYPES)
                     .then { |q| @type_filter ? q.where(doc_type: @type_filter) : q }
                     .includes(:project, :author)
                     .order(updated_at: :desc)
    end

    def show; end

    private

    def set_document
      project_ids = current_customer.installations.pluck(:project_id).compact.uniq
      @document   = Document.where(project_id: project_ids, doc_type: VISIBLE_TYPES).find(params[:id])
    end
  end
end
