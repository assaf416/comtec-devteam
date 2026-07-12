FactoryBot.define do
  factory :meeting_attendee do
    meeting { nil }
    user { nil }
    attended { false }
  end
end
