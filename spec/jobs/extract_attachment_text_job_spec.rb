require "rails_helper"

RSpec.describe ExtractAttachmentTextJob, type: :job do
  # Suppress the auto (inline) extraction on create so each test drives it explicitly.
  before { allow(described_class).to receive(:perform_later) }

  def build_attachment(fixture, mime)
    create(:attachment, fixture: fixture, mime: mime)
  end

  {
    "notes.txt"        => [ "text/plain",   "payment gateway" ],
    "spec.md"          => [ "text/markdown", "payment gateway" ],
    "data.csv"         => [ "text/csv",     "developer" ],
    "page.html"        => [ "text/html",    "Quarterly Report" ],
    "requirements.pdf" => [ "application/pdf", "payment gateway" ],
    "sample.docx"      => [ "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "payment gateway" ],
    "sample.xlsx"      => [ "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "Estimation" ]
  }.each do |fixture, (mime, needle)|
    it "extracts text from #{fixture}" do
      attachment = build_attachment(fixture, mime)

      described_class.perform_now(attachment.id)

      attachment.reload
      expect(attachment).to be_done
      expect(attachment.extracted_text).to include(needle)
    end
  end

  it "strips HTML tags from html content" do
    attachment = build_attachment("page.html", "text/html")
    described_class.perform_now(attachment.id)
    expect(attachment.reload.extracted_text).not_to include("<h1>")
  end

  it "marks images as unsupported" do
    attachment = build_attachment("diagram.png", "image/png")
    described_class.perform_now(attachment.id)

    attachment.reload
    expect(attachment).to be_unsupported
    expect(attachment.extracted_text).to eq("diagram.png")
  end

  it "does nothing when the attachment is missing" do
    expect { described_class.perform_now(-1) }.not_to raise_error
  end
end
