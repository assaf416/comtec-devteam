class MeetingCommentsController < ApplicationController
  before_action :set_meeting

  def create
    body = params.dig(:body) || params.dig(:comment, :body)
    kind = params.dig(:comment, :kind).presence_in(Comment.kinds.keys) || "note"
    if body.present?
      @meeting.comments.create!(body: body, kind: kind, author: current_user)
    end
    redirect_to @meeting
  end

  def destroy
    comment = @meeting.comments.find(params[:id])
    comment.destroy if comment.author == current_user
    redirect_to @meeting
  end

  private

  def set_meeting
    @meeting = Meeting.find(params[:meeting_id])
  end
end
