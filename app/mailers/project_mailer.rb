class ProjectMailer < ApplicationMailer
  # Sent to a user when they are added to a project
  def member_added(membership, added_by)
    @membership = membership
    @user       = membership.user
    @project    = membership.project
    @added_by   = added_by
    @role       = membership.role

    mail(
      to:      @user.email,
      subject: "You've been added to #{@project.name}"
    )
  end

  # Sent to a user when they are removed from a project
  def member_removed(user, project, removed_by)
    @user       = user
    @project    = project
    @removed_by = removed_by

    mail(
      to:      @user.email,
      subject: "You've been removed from #{@project.name}"
    )
  end
end
