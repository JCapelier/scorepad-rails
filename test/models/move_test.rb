require "test_helper"

class MoveTest < ActiveSupport::TestCase
  # Associations
  should belong_to(:session_player)
  should belong_to(:round)

  # Sanity build (ensures factory/quick create works)
  test "factory builds a valid Move" do
    record = defined?(FactoryBot) ? build(:move) : Move.new
    assert record.valid?, record.errors.full_messages.to_sentence
  end
end
