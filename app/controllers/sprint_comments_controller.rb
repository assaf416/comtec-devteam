class SprintCommentsController < ApplicationController
  before_action :set_sprint

  def create
    @comment = @sprint.comments.build(
      body:   params[:comment][:body].to_s.strip,
      kind:   params.dig(:comment, :kind).presence_in(Comment.kinds.keys) || "note",
      author: current_user
    )

    if @comment.body.blank?
      redirect_to @sprint, alert: "Comment cannot be blank"
      return
    end

    if @comment.save
      redirect_to @sprint, notice: "Comment added", anchor: "comment-#{@comment.id}"
    else
      redirect_to @sprint, alert: @comment.errors.full_messages.to_sentence
    end
  end

  def destroy
    @comment = @sprint.comments.find(params[:id])
    unless @comment.author == current_user || current_user.admin?
      redirect_to @sprint, alert: "You can only delete your own comments"
      return
    end
    @comment.destroy
    redirect_to @sprint, notice: "Comment deleted"
  end

  private

  def set_sprint
    @sprint = Sprint.find(params[:sprint_id])
  end
end
