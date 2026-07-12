FactoryBot.define do
  factory :milestone do
    name { "MyString" }
    description { "MyText" }
    project { nil }
    due_date { "2026-05-22" }
    status { 1 }
  end
end
