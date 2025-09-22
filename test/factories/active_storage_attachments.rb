FactoryBot.define do
  factory :active_storage_attachment do
    association :record
    association :blob
    sequence(:name) { |n| "name_#{n}" }
    sequence(:record_type) { |n| "record_type_#{n}" }
  end
end
