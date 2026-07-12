require 'rails_helper'

RSpec.describe "Ticket attachments", type: :model do
  let(:project) { create(:project) }
  let(:ticket)  { create(:ticket, project: project) }

  def attach(filename:, content_type:, data: "x")
    ticket.attachments.attach(io: StringIO.new(data), filename: filename, content_type: content_type)
  end

  it "accepts an image" do
    attach(filename: "shot.png", content_type: "image/png")
    expect(ticket).to be_valid
  end

  it "accepts a CSV" do
    attach(filename: "data.csv", content_type: "text/csv", data: "a,b\n1,2")
    expect(ticket).to be_valid
  end

  it "accepts an Excel file" do
    attach(filename: "sheet.xlsx", content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    expect(ticket).to be_valid
  end

  it "accepts a movie" do
    attach(filename: "demo.mp4", content_type: "video/mp4")
    expect(ticket).to be_valid
  end

  it "rejects an unsupported type (e.g. executable)" do
    attach(filename: "virus.exe", content_type: "application/x-msdownload")
    expect(ticket).not_to be_valid
    expect(ticket.errors[:attachments].join).to match(/unsupported type/i)
  end

  it "stores multiple attachments via has_many_attached" do
    attach(filename: "a.png", content_type: "image/png")
    attach(filename: "b.csv", content_type: "text/csv")
    expect(ticket.attachments.count).to eq(2)
  end
end
