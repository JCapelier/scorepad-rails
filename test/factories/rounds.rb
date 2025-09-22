FactoryBot.define do
  factory :round do
    status { "pending" }
    association :scoresheet
  end
end
