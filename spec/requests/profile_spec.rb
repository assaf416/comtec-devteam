require 'rails_helper'

RSpec.describe "Profile", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /profile/edit" do
    it "renders the profile page" do
      get edit_profile_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("avatar")
    end
  end

  describe "PATCH /profile" do
    it "updates the avatar" do
      avatar = fixture_file_upload(
        Rails.root.join("spec/fixtures/files/test_avatar.png"),
        "image/png"
      )
      patch profile_path, params: { user: { avatar: avatar } }
      expect(response).to redirect_to(edit_profile_path)
      user.reload
      expect(user.avatar).to be_attached
    end

    it "rejects non-image files" do
      bad_file = fixture_file_upload(
        Rails.root.join("spec/fixtures/files/test_document.txt"),
        "text/plain"
      )
      patch profile_path, params: { user: { avatar: bad_file } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "updates name alongside avatar" do
      avatar = fixture_file_upload(
        Rails.root.join("spec/fixtures/files/test_avatar.png"),
        "image/png"
      )
      patch profile_path, params: { user: { name: "New Name", avatar: avatar } }
      expect(response).to redirect_to(edit_profile_path)
      user.reload
      expect(user.name).to eq("New Name")
      expect(user.avatar).to be_attached
    end
  end
end
