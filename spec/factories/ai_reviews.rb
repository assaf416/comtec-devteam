FactoryBot.define do
  factory :ai_review do
    kind   { :code_review }
    status { :completed }
    llm_model { "llama3.1" }
    body   { "VERDICT: pass\nLooks good." }
  end
end
