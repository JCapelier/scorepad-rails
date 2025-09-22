require "test_helper"

class ActiveStorage::AttachmentTest < ActiveSupport::TestCase
  # Associations
  should belong_to(:record)
  should belong_to(:blob)

  # Validations
  should validate_presence_of(:record)
  should validate_presence_of(:blob)
  should validate_uniqueness_of(:record_type)
  should validate_uniqueness_of(:record_id)
  should validate_uniqueness_of(:name)
  should validate_uniqueness_of(:blob_id)

  # Sanity build (ensures factory/quick create works)
  test "factory builds a valid ActiveStorage::Attachment" do
    record = defined?(FactoryBot) ? build(:active_storage_attachment) : ActiveStorage::Attachment.new
    assert record.valid?, record.errors.full_messages.to_sentence
  end
end
