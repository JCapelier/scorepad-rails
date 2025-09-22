require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Associations
  should have_one(:avatar_attachment)
  should have_one(:avatar_blob)
  should have_many(:session_players)
  should have_many(:game_sessions)

  # Sanity build (ensures factory/quick create works)
  test "factory builds a valid User" do
    record = defined?(FactoryBot) ? build(:user) : User.new
    assert record.valid?, record.errors.full_messages.to_sentence
  end
end
