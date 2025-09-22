require "test_helper"

class ActiveStorage::BlobTest < ActiveSupport::TestCase
  # Associations
  should have_one(:preview_image_attachment)
  should have_one(:preview_image_blob)
  should have_many(:variant_records)
  should have_many(:attachments)

  # Validations
  should validate_presence_of(:service_name)
  should validate_presence_of(:checksum)
  should validate_uniqueness_of(:key)

  # Sanity build (ensures factory/quick create works)
  test "factory builds a valid ActiveStorage::Blob" do
    record = defined?(FactoryBot) ? build(:active_storage_blob) : ActiveStorage::Blob.new
    assert record.valid?, record.errors.full_messages.to_sentence
  end
end
