FactoryBot.define do
  factory :note do
    user
    body { "Remember to review the PR" }
  end
end
