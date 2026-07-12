FactoryBot.define do
  factory :ci_run do
    project
    sequence(:build_number) { |n| "build-#{n}" }
    status    { :passed }
    started_at { Time.current }
    branch_name { "main" }
    commit_sha  { SecureRandom.hex(20) }
  end
end
