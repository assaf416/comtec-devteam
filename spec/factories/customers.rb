FactoryBot.define do
  factory :customer do
    name          { Faker::Company.name }
    company       { Faker::Company.name }
    email         { Faker::Internet.unique.email }
    phone         { Faker::PhoneNumber.phone_number }
    contact_person { Faker::Name.name }
    notes         { Faker::Lorem.sentence }
    active        { true }
  end

  factory :inactive_customer, parent: :customer do
    active { false }
  end
end
