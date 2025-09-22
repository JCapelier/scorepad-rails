require "test_helper"

class MoveTest < ActiveSupport::TestCase
  # Associations
  should belong_to(:session_player)
  should belong_to(:round)

  # Validations
  should validate_presence_of(:session_player)
  should validate_presence_of(:round)
  should validate_inclusion_of(:move_type).in_array(["first_finisher", "bid", "tricks"])

  # Sanity build (ensures factory/quick create works)
  test "factory builds a valid Move" do
    record = defined?(FactoryBot) ? build(:move) : Move.new
    assert record.valid?, record.errors.full_messages.to_sentence
  end
end
