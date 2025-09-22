FactoryBot.define do
  factory :move do
    move_type { "first_finisher" }   # valid default
    association :session_player
    association :round
  end
end
