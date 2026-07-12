class AllDocumentsController < ApplicationController
  def index
    scope = Document.includes(:project, :author).order(updated_at: :desc)

    if params[:doc_type].present?
      scope = scope.where(doc_type: params[:doc_type])
    end

    if params[:q].present?
      q = "%#{params[:q]}%"
      scope = scope.where("title LIKE ? OR content LIKE ?", q, q)
    end

    @documents       = scope.limit(200)
    @grouped         = @documents.group_by(&:project)
    @doc_type_counts = Document.group(:doc_type).count
  end
end
