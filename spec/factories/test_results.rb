FactoryBot.define do
  factory :test_result do
    ci_run
    suite_name { "Unit Tests" }
    total   { 20 }
    passed  { 18 }
    failed  { 1 }
    skipped { 1 }
  end
end
