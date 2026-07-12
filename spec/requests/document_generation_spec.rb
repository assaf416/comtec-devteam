require 'rails_helper'

# AI document generation on the project Documents area. The local LLM (Ollama)
# is stubbed so these run offline.
RSpec.describe "AI document generation", type: :request do
  let(:user)    { create(:user, role: :admin) }
  let(:project) { create(:project, name: "Print Server") }

  before do
    sign_in user
    create(:ticket, project: project, kind: :story, title: "As a user I want to print", description: "Print to a queue")
  end

  describe "POST /projects/:project_id/documents/generate" do
    it "generates a status presentation document" do
      allow_any_instance_of(Ai::OllamaClient).to receive(:chat)
        .and_return("## Overview\n- The project is progressing well\n\n## Next steps\n- Ship it")

      expect {
        post generate_project_documents_path(project), params: { kind: "presentation" }
      }.to change(project.documents.where(doc_type: :presentation), :count).by(1)

      doc = project.documents.last
      expect(doc.content).to include("Overview")
      expect(doc.title).to include("Status Presentation")
      expect(response).to redirect_to(document_path(doc))
    end

    it "generates a spec document, honouring an optional topic" do
      allow_any_instance_of(Ai::OllamaClient).to receive(:chat)
        .and_return("## Overview\nSpec body.\n\n## Functional requirements\n- Print")

      expect {
        post generate_project_documents_path(project), params: { kind: "spec", topic: "Printing" }
      }.to change(project.documents.where(doc_type: :spec), :count).by(1)

      doc = project.documents.last
      expect(doc.title).to eq("Printing — Specification")
      expect(doc.doc_type).to eq("spec")
    end

    it "rejects an unknown document kind" do
      expect {
        post generate_project_documents_path(project), params: { kind: "bogus" }
      }.not_to change(Document, :count)
      expect(response).to redirect_to(project_documents_path(project))
    end

    it "does not create a document when the LLM is unreachable" do
      allow_any_instance_of(Ai::OllamaClient).to receive(:chat)
        .and_raise(Ai::OllamaClient::Error, "connection refused")

      expect {
        post generate_project_documents_path(project), params: { kind: "presentation" }
      }.not_to change(Document, :count)
      expect(flash[:alert]).to match(/could not complete/i)
    end
  end

  describe "the project page exposes the generators" do
    it "shows the AI generate buttons" do
      get project_path(project)
      expect(response.body).to include(generate_project_documents_path(project))
      expect(response.body).to include("Status Presentation")
      expect(response.body).to include("Generate Spec")
    end
  end
end
