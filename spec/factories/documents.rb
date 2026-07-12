FactoryBot.define do
  factory :document do
    title { "MyString" }
    content { "MyText" }
    doc_type { 1 }
    project { nil }
    author { nil }
    summary { "MyText" }
    version_number { "MyString" }
  end
end
