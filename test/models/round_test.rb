require "test_helper"

class RoundTest < ActiveSupport::TestCase
  # Associations
  should belong_to(:scoresheet)
  should have_many(:moves)

  # Sanity build (ensures factory/quick create works)
  test "factory builds a valid Round" do
    record = defined?(FactoryBot) ? build(:round) : Round.new
    assert record.valid?, record.errors.full_messages.to_sentence
  end
end
