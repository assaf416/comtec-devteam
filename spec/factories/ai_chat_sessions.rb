FactoryBot.define do
  factory :ai_chat_session do
    user
    project
    title { "Chat" }
  end
end
