FactoryBot.define do
  factory :time_log do
    user
    project
    hours    { 2.5 }
    spent_on { Date.current }
    note     { "Worked on the thing" }
  end
end
