FactoryBot.define do
  factory :ticket do
    project
    sequence(:title) { |n| "Ticket #{n}" }
    status   { :open }
    priority { :medium }
  end
end
