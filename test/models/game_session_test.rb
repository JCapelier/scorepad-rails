require "test_helper"

class GameSessionTest < ActiveSupport::TestCase
  # Associations
  should belong_to(:game)
  should have_one(:scoresheet)
  should have_many(:session_players)

  # Validations
  should validate_presence_of(:game)
  should validate_inclusion_of(:status).in_array(["pending", "active", "completed"])

  # Sanity build (ensures factory/quick create works)
  test "factory builds a valid GameSession" do
    record = defined?(FactoryBot) ? build(:game_session) : GameSession.new
    assert record.valid?, record.errors.full_messages.to_sentence
  end
end
