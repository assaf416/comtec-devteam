FactoryBot.define do
  factory :pull_request do
    title { "MyString" }
    description { "MyText" }
    status { 1 }
    project { nil }
    ticket { nil }
    pr_number { 1 }
    author { "MyString" }
    gitea_url { "MyString" }
    merged_at { "2026-05-22 18:30:18" }
  end
end
