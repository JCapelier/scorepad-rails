FactoryBot.define do
  factory :game_session do
    status { "pending" }         # valid value
    association :game            # required association
  end
end
