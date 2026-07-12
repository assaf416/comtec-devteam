FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "Project #{n}" }
    description { Faker::Lorem.paragraph }
    tech_stack   { "Rails / PostgreSQL" }
    active       { true }
    default_branch { "main" }
    gitea_repo_id  { "devteam/#{Faker::Internet.slug}" }
  end
end
