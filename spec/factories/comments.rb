FactoryBot.define do
  factory :comment do
    body { "MyText" }
    author { nil }
    commentable { nil }
  end
end
