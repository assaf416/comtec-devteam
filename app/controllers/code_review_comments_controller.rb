# Comments left during a code review (polymorphic Comment on a CodeReview).
class CodeReviewCommentsController < ApplicationController
  before_action :set_code_review

  def create
    @comment = @code_review.comments.build(
      body:   params[:comment][:body].to_s.strip,
      kind:   params.dig(:comment, :kind).presence_in(Comment.kinds.keys) || "note",
      author: current_user
    )

    if @comment.body.blank?
      redirect_to @code_review, alert: "Comment cannot be blank"
      return
    end

    if @comment.save
      redirect_to code_review_path(@code_review, anchor: "comment-#{@comment.id}"), notice: "Comment added"
    else
      redirect_to @code_review, alert: @comment.errors.full_messages.to_sentence
    end
  end

  def destroy
    @comment = @code_review.comments.find(params[:id])
    unless @comment.author == current_user || current_user.admin?
      redirect_to @code_review, alert: "You can only delete your own comments"
      return
    end
    @comment.destroy
    redirect_to @code_review, notice: "Comment deleted"
  end

  private

  def set_code_review
    @code_review = CodeReview.find(params[:code_review_id])
  end
end
