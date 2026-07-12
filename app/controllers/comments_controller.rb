class CommentsController < ApplicationController
  before_action :set_ticket
  before_action :require_project_membership

  def create
    @comment = @ticket.comments.build(
      body:   params[:comment][:body].to_s.strip,
      kind:   params.dig(:comment, :kind).presence_in(Comment.kinds.keys) || "note",
      author: current_user
    )

    if @comment.body.blank?
      redirect_to @ticket, alert: "Comment cannot be blank"
      return
    end

    if @comment.save
      redirect_to @ticket, notice: "Comment added", anchor: "comment-#{@comment.id}"
    else
      redirect_to @ticket, alert: @comment.errors.full_messages.to_sentence
    end
  end

  def destroy
    @comment = @ticket.comments.find(params[:id])
    unless @comment.author == current_user || current_user.admin?
      redirect_to @ticket, alert: "You can only delete your own comments"
      return
    end
    @comment.destroy
    redirect_to @ticket, notice: "Comment deleted"
  end

  private

  def set_ticket
    @ticket  = Ticket.includes(:project).find(params[:ticket_id])
    @project = @ticket.project
  end

  def require_project_membership
    unless current_user.admin? || @project.members.include?(current_user)
      redirect_to @ticket, alert: "Only project members can comment"
    end
  end
end
