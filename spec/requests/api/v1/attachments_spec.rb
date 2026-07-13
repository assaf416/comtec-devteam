require "rails_helper"

RSpec.describe "Api::V1::Attachments", type: :request do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }
  let(:headers) { { "Authorization" => "Bearer #{user.api_token}" } }

  describe "POST /api/v1/attachments" do
    let(:file) { fixture_file_upload("notes.txt", "text/plain") }

    it "uploads a file and returns the attachment JSON" do
      expect do
        post "/api/v1/attachments",
             params: { project_id: project.id, file: file, title: "Meeting notes" },
             headers: headers
      end.to change(Attachment, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["title"]).to eq("Meeting notes")
      expect(body["filename"]).to eq("notes.txt")
      expect(body["project"]["id"]).to eq(project.id)

      attachment = Attachment.last
      expect(attachment.uploaded_by).to eq(user)
    end

    it "requires authentication" do
      post "/api/v1/attachments", params: { project_id: project.id, file: file }
      expect(response).to have_http_status(:unauthorized)
    end

    it "404s for an unknown project" do
      post "/api/v1/attachments",
           params: { project_id: 0, file: file }, headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "422s without a file" do
      post "/api/v1/attachments",
           params: { project_id: project.id }, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/attachments" do
    it "lists and searches attachments" do
      hit = create(:attachment, project: project, title: "Payment spec")
      hit.update!(extracted_text: "payment gateway details")

      get "/api/v1/attachments", params: { q: "payment gateway" }, headers: headers

      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body).map { |a| a["id"] }
      expect(ids).to include(hit.id)
    end
  end
end
