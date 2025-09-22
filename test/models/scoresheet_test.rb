require "test_helper"

class ScoresheetTest < ActiveSupport::TestCase
  # Associations
  should belong_to(:game_session)
  should have_one(:game)
  should have_many(:rounds)
  should have_many(:session_players)
  should have_many(:moves)

  # Validations
  should validate_presence_of(:game_session)

  # Sanity build (ensures factory/quick create works)
  test "factory builds a valid Scoresheet" do
    record = defined?(FactoryBot) ? build(:scoresheet) : Scoresheet.new
    assert record.valid?, record.errors.full_messages.to_sentence
  end
end
