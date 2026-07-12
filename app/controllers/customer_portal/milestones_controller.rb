module CustomerPortal
  class MilestonesController < BaseController
    def index
      project_ids = current_customer.installations.pluck(:project_id).compact.uniq

      @active_milestones    = Milestone.where(project_id: project_ids)
                                .where.not(status: :completed)
                                .includes(:project)
                                .order(:due_date)

      @completed_milestones = Milestone.where(project_id: project_ids, status: :completed)
                                .includes(:project)
                                .order(updated_at: :desc)
                                .limit(10)
    end
  end
end
