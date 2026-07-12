FactoryBot.define do
  factory :meeting do
    project
    title        { Faker::Lorem.sentence(word_count: 3) }
    scheduled_at { 1.day.from_now }
    meeting_type { :daily_standup }
    status       { :scheduled }
    jitsi_room   { "devteam-#{SecureRandom.hex(6)}" }
    duration_minutes { 30 }
  end
end
