FactoryBot.define do
  factory :customer_ticket do
    association :customer
    title    { Faker::Lorem.sentence(word_count: 5) }
    body     { Faker::Lorem.paragraph }
    status   { :open }
    priority { :medium }
    assigned_to      { nil }
    internal_ticket  { nil }
  end

  factory :resolved_customer_ticket, parent: :customer_ticket do
    status      { :resolved }
    resolved_at { 1.day.ago }
  end

  factory :critical_customer_ticket, parent: :customer_ticket do
    priority { :critical }
    status   { :open }
  end
end
