FactoryBot.define do
  factory :active_storage_variant_record do
    association :blob
    sequence(:variation_digest) { |n| "variation_digest_#{n}" }
  end
end
