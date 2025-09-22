require "test_helper"

class GameTest < ActiveSupport::TestCase
  # Associations
  should have_many(:game_sessions)

  # Validations

  # Sanity build (ensures factory/quick create works)
  test "factory builds a valid Game" do
    record = defined?(FactoryBot) ? build(:game) : Game.new
    assert record.valid?, record.errors.full_messages.to_sentence
  end
end
