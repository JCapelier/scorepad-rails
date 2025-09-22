require "test_helper"

class RoundTest < ActiveSupport::TestCase
  # Associations
  should belong_to(:scoresheet)
  should have_many(:moves)

  # Validations
  should validate_presence_of(:scoresheet)
  should validate_inclusion_of(:status).in_array(["pending", "active", "completed"])

  # Sanity build (ensures factory/quick create works)
  test "factory builds a valid Round" do
    record = defined?(FactoryBot) ? build(:round) : Round.new
    assert record.valid?, record.errors.full_messages.to_sentence
  end
end
