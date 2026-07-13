FactoryBot.define do
  factory :attachment do
    association :project
    association :uploaded_by, factory: :user
    title { nil }

    transient do
      fixture  { "notes.txt" }
      mime     { "text/plain" }
    end

    after(:build) do |attachment, evaluator|
      attachment.file.attach(
        io:           File.open(Rails.root.join("spec/fixtures/files", evaluator.fixture)),
        filename:     evaluator.fixture,
        content_type: evaluator.mime
      )
    end
  end
end
