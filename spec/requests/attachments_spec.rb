require "rails_helper"

RSpec.describe "Attachments", type: :request do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }

  before { sign_in user }

  describe "POST /projects/:project_id/attachments" do
    it "uploads multiple files at once" do
      files = [
        fixture_file_upload("notes.txt", "text/plain"),
        fixture_file_upload("spec.md", "text/markdown")
      ]

      expect do
        post project_attachments_path(project), params: { attachment: { files: files } }
      end.to change(Attachment, :count).by(2)

      expect(response).to redirect_to(project_attachments_path(project))
      expect(Attachment.last.uploaded_by).to eq(user)
    end

    it "re-renders with an alert when no files are selected" do
      post project_attachments_path(project), params: { attachment: { files: [] } }
      expect(response).to redirect_to(new_project_attachment_path(project))
    end
  end

  describe "GET /attachments/:id" do
    it "records that the current user opened the file" do
      attachment = create(:attachment, project: project)

      expect do
        get attachment_path(attachment)
      end.to change { AttachmentView.where(user: user, attachment: attachment).count }.by(1)

      expect(response).to have_http_status(:ok)
    end

    it "refreshes viewed_at on a repeat open without duplicating" do
      attachment = create(:attachment, project: project)
      get attachment_path(attachment)
      expect do
        get attachment_path(attachment)
      end.not_to change(AttachmentView, :count)
    end
  end

  describe "GET /attachments (search)" do
    it "finds files by extracted content" do
      hit = create(:attachment, project: project, title: "Spec")
      hit.update!(extracted_text: "payment gateway")

      get attachments_path, params: { q: "payment gateway" }

      expect(response.body).to include("Spec")
    end
  end
end
