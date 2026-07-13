require "rails_helper"

RSpec.describe Attachment, type: :model do
  # Keep model specs isolated from the (inline) extraction job.
  before { allow(ExtractAttachmentTextJob).to receive(:perform_later) }

  it "is valid with a file attached" do
    expect(build(:attachment)).to be_valid
  end

  it "requires a file" do
    attachment = build(:attachment)
    attachment.file.detach
    expect(attachment).not_to be_valid
    expect(attachment.errors[:file]).to be_present
  end

  it "rejects unsupported content types" do
    attachment = build(:attachment, fixture: "notes.txt", mime: "application/x-msdownload")
    attachment.file.blob.update!(content_type: "application/x-msdownload")
    expect(attachment).not_to be_valid
  end

  it "defaults the title to the filename" do
    attachment = create(:attachment, fixture: "spec.md", mime: "text/markdown", title: nil)
    expect(attachment.title).to eq("spec.md")
  end

  it "exposes filename, content_type and byte_size" do
    attachment = create(:attachment, fixture: "notes.txt")
    expect(attachment.filename).to eq("notes.txt")
    expect(attachment.content_type).to eq("text/plain")
    expect(attachment.byte_size).to be > 0
  end

  describe ".search" do
    it "matches on title and extracted_text" do
      project = create(:project)
      hit  = create(:attachment, project: project, title: "Payment spec")
      hit.update!(extracted_text: "the payment gateway supports refunds")
      miss = create(:attachment, project: project, title: "Unrelated")

      expect(Attachment.search("payment gateway")).to include(hit)
      expect(Attachment.search("payment")).not_to include(miss)
    end
  end

  it "enqueues extraction after create" do
    attachment = create(:attachment)
    expect(ExtractAttachmentTextJob).to have_received(:perform_later).with(attachment.id)
  end
end
