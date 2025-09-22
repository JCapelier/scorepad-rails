require "test_helper"

class SessionPlayerTest < ActiveSupport::TestCase
  # Associations
  should belong_to(:user)
  should belong_to(:game_session)
  should have_many(:moves)

  # Validations
  should validate_presence_of(:guest_name)
  should validate_presence_of(:game_session)

  # Sanity build (ensures factory/quick create works)
  test "factory builds a valid SessionPlayer" do
    record = defined?(FactoryBot) ? build(:session_player) : SessionPlayer.new
    assert record.valid?, record.errors.full_messages.to_sentence
  end
end
