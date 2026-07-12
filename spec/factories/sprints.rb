FactoryBot.define do
  factory :sprint do
    association :project
    sequence(:name) { |n| "Sprint #{n}" }
    start_date { Date.today }
    end_date   { Date.today + 14 }
    status     { :planning }
    goals      { "Deliver core features" }
    velocity   { 20 }
  end

  factory :active_sprint, parent: :sprint do
    status     { :active }
    start_date { Date.today - 3 }
    end_date   { Date.today + 11 }
  end

  factory :completed_sprint, parent: :sprint do
    status     { :completed }
    start_date { Date.today - 28 }
    end_date   { Date.today - 14 }
  end
end
