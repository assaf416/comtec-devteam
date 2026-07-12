# Quick-contact from the top toolbar: send a teammate a short in-app message.
# (Video calls go straight to the meetings/Jitsi flow via new_meeting_path.)
class QuickContactsController < ApplicationController
  def create
    recipient = User.find(params[:user_id])
    body      = params[:body].to_s.strip

    if body.blank?
      redirect_back fallback_location: today_path, alert: "Message cannot be blank."
      return
    end

    text = "💬 #{current_user.display_name}: #{body}"
    Notification.create!(
      recipient: recipient,
      type:      "Notification",
      message:   text,
      params:    { "message" => text, "url" => today_path }
    )

    redirect_back fallback_location: today_path,
                  notice: "Message sent to #{recipient.display_name}."
  end
end
