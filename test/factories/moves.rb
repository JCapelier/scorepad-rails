FactoryBot.define do
  factory :move do
    association :session_player
    association :round
  end
end
