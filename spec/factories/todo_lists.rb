FactoryBot.define do
  factory :todo_list do
    user
    title { "My tasks" }
  end

  factory :todo_item do
    todo_list
    sequence(:content) { |n| "Task #{n}" }
    done { false }
  end
end
