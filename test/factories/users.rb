FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    sequence(:reset_password_token) { |n| "reset_password_token_#{n}" }
    admin { false }
  end
end
