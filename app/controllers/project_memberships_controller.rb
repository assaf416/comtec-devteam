class ProjectMembershipsController < ApplicationController
  before_action :set_project
  before_action :authorize_admin_or_lead

  def create
    user = User.find(params[:project_membership][:user_id])
    role = params[:project_membership][:role].presence || "developer"

    membership = @project.project_memberships.build(user: user, role: role,
                                                     notes: params[:project_membership][:notes])

    if membership.save
      # Email notification (deliver_later so it never blocks the request)
      ProjectMailer.member_added(membership, current_user).deliver_later

      # Activity record
      Activity.create!(
        project:      @project,
        user:         current_user,
        subject_user: user,
        event_type:   :member_added,
        description:  "#{current_user.display_name} added #{user.display_name} as #{role}",
        metadata:     { role: role, user_email: user.email }
      )

      redirect_to project_path(@project, anchor: "members"),
                  notice: "#{user.display_name} added to #{@project.name}"
    else
      redirect_to project_path(@project, anchor: "members"),
                  alert: membership.errors.full_messages.to_sentence
    end
  end

  def destroy
    membership = @project.project_memberships.find(params[:id])
    user       = membership.user

    membership.destroy

    # Email notification
    ProjectMailer.member_removed(user, @project, current_user).deliver_later

    # Activity record
    Activity.create!(
      project:      @project,
      user:         current_user,
      subject_user: user,
      event_type:   :member_removed,
      description:  "#{current_user.display_name} removed #{user.display_name} from the project",
      metadata:     { user_email: user.email }
    )

    redirect_to project_path(@project, anchor: "members"),
                notice: "#{user.display_name} removed from #{@project.name}"
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def authorize_admin_or_lead
    is_admin = current_user.admin?
    is_lead  = @project.project_memberships.exists?(user: current_user, role: :lead)
    unless is_admin || is_lead
      redirect_to @project, alert: "Only project leads and admins can manage members"
    end
  end
end
