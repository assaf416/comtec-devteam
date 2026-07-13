require "rails_helper"

RSpec.describe "Notes", type: :request do
  let(:user) { create(:user) }
  before { sign_in user }

  describe "GET /notes" do
    it "lists my active notes and hides archived under a section" do
      create(:note, user: user, body: "Active one")
      create(:note, user: user, body: "Old one", archived: true)
      get notes_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Active one")
    end
  end

  describe "POST /notes (quick capture)" do
    it "creates a note from a single field" do
      expect {
        post notes_path, params: { note: { body: "Quick captured note" } }
      }.to change(user.notes, :count).by(1)
      expect(response).to redirect_to(notes_path)
    end

    it "rejects a fully empty note" do
      post notes_path, params: { note: { title: "", body: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "managing a note" do
    let(:note) { create(:note, user: user) }

    it "pins and unpins" do
      patch toggle_pin_note_path(note)
      expect(note.reload.pinned).to be true
      patch toggle_pin_note_path(note)
      expect(note.reload.pinned).to be false
    end

    it "archives" do
      patch toggle_archive_note_path(note)
      expect(note.reload.archived).to be true
    end

    it "edits the body" do
      patch note_path(note), params: { note: { body: "Edited" } }
      expect(note.reload.body).to eq("Edited")
    end

    it "deletes" do
      note
      expect { delete note_path(note) }.to change(user.notes, :count).by(-1)
    end

    it "does not expose another user's note" do
      other = create(:note, user: create(:user))
      patch toggle_pin_note_path(other)
      expect(response).to have_http_status(:not_found)
      expect(other.reload.pinned).to be false
    end
  end
end
