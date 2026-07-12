FactoryBot.define do
  factory :deployment do
    project { nil }
    version { "MyString" }
    environment { "MyString" }
    deployed_by { nil }
    deployed_at { "2026-05-22 18:30:30" }
    status { 1 }
    machine_name { "MyString" }
    client_account { nil }
    deploy_type { 1 }
    notes { "MyText" }
  end
end
