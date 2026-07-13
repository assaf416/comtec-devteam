FactoryBot.define do
  factory :attachment_view do
    association :user
    association :attachment
    viewed_at { Time.current }
  end
end
