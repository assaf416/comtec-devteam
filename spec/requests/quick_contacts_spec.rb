require 'rails_helper'

RSpec.describe "QuickContacts", type: :request do
  let(:user)      { create(:user, name: "Me") }
  let(:teammate)  { create(:user, name: "Dana Dev") }

  before { sign_in user }

  describe "POST /quick_contact" do
    it "sends an in-app message (notification) to the teammate" do
      expect {
        post quick_contact_path, params: { user_id: teammate.id, body: "ping!" },
             headers: { "HTTP_REFERER" => today_path }
      }.to change { teammate.notifications.count }.by(1)

      note = teammate.notifications.last
      expect(note.message_text).to include("Me")
      expect(note.message_text).to include("ping!")
      expect(flash[:notice]).to include("Dana Dev")
    end

    it "rejects a blank message" do
      expect {
        post quick_contact_path, params: { user_id: teammate.id, body: "  " },
             headers: { "HTTP_REFERER" => today_path }
      }.not_to change(Notification, :count)
      expect(flash[:alert]).to be_present
    end
  end

  describe "toolbar widget" do
    it "renders the find-a-teammate popover with call + message actions" do
      teammate
      get today_path
      expect(response.body).to include('data-controller="quick-contact"')
      expect(response.body).to include(new_meeting_path(invite: teammate.id)) # Jitsi call
      expect(response.body).to include(quick_contact_path)                    # message form
    end
  end
end
