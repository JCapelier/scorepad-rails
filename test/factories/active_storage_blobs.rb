FactoryBot.define do
  factory :active_storage_blob do
    sequence(:key) { |n| "key_#{n}" }
    filename { Faker::Lorem.words(number: 2).join(" ") }
    service_name { Faker::Lorem.words(number: 2).join(" ") }
    byte_size { 1 }
  end
end
