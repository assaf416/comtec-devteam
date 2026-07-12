FactoryBot.define do
  factory :task do
    association :ticket
    sequence(:description) { |n| "Task #{n}" }
    estimation { "2h" }
  end
end
