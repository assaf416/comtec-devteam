FactoryBot.define do
  factory :branch do
    name { "MyString" }
    project { nil }
    ticket { nil }
    status { 1 }
    created_at_gitea { "2026-05-22 18:30:17" }
  end
end
