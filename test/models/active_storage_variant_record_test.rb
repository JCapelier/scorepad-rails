require "test_helper"

class ActiveStorage::VariantRecordTest < ActiveSupport::TestCase
  # Associations
  should belong_to(:blob)
  should have_one(:image_attachment)
  should have_one(:image_blob)

  # Validations
  should validate_presence_of(:blob)
  should validate_uniqueness_of(:blob_id)
  should validate_uniqueness_of(:variation_digest)

  # Sanity build (ensures factory/quick create works)
  test "factory builds a valid ActiveStorage::VariantRecord" do
    record = defined?(FactoryBot) ? build(:active_storage_variant_record) : ActiveStorage::VariantRecord.new
    assert record.valid?, record.errors.full_messages.to_sentence
  end
end
