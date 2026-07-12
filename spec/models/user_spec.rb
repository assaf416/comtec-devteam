require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
  end

  describe 'associations' do
    it { should have_many(:assigned_tickets) }
    it { should have_many(:organized_meetings) }
    it { should have_many(:notifications) }
  end

  describe '#display_name' do
    it 'returns name when present' do
      user = build(:user, name: 'Alice Smith')
      expect(user.display_name).to eq('Alice Smith')
    end
  end

  describe '#initials' do
    it 'returns two-letter initials from full name' do
      user = build(:user, name: 'Alice Smith')
      expect(user.initials).to eq('AS')
    end

    it 'returns first two chars for single-word name' do
      user = build(:user, name: 'Admin')
      expect(user.initials).to eq('AD')
    end

    it 'handles three-word names using first and last' do
      user = build(:user, name: 'John Bob Doe')
      expect(user.initials).to eq('JD')
    end
  end

  describe 'avatar' do
    let(:user) { create(:user) }

    it 'can attach an avatar' do
      user.avatar.attach(
        io: StringIO.new(png_pixel),
        filename: 'avatar.png',
        content_type: 'image/png'
      )
      expect(user.avatar).to be_attached
    end

    it 'rejects non-image content types' do
      user.avatar.attach(
        io: StringIO.new("not an image"),
        filename: 'malware.exe',
        content_type: 'application/octet-stream'
      )
      expect(user).not_to be_valid
      expect(user.errors[:avatar]).to include("must be a PNG, JPEG, GIF, or WebP image")
    end

    it 'rejects files over 5 MB' do
      large_data = "x" * 6.megabytes
      user.avatar.attach(
        io: StringIO.new(large_data),
        filename: 'huge.png',
        content_type: 'image/png'
      )
      expect(user).not_to be_valid
      expect(user.errors[:avatar]).to include("must be less than 5 MB")
    end
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(developer: 0, team_lead: 1, project_manager: 2, admin: 3, qa: 4) }
  end

  private

  # Minimal valid 1x1 PNG
  def png_pixel
    [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
      0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
      0x00, 0x00, 0x02, 0x00, 0x01, 0xE2, 0x21, 0xBC, 0x33, 0x00, 0x00, 0x00,
      0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
    ].pack("C*")
  end
end
