FactoryBot.define do
  factory :installation do
    association :customer
    project     { nil }
    deployment  { nil }
    software_name { Faker::App.name }
    version       { Faker::App.version }
    environment   { "production" }
    installed_at  { 1.week.ago }
    status        { :active }
    notes         { nil }
  end

  factory :outdated_installation, parent: :installation do
    status { :outdated }
  end

  factory :failed_installation, parent: :installation do
    status { :failed }
  end
end
