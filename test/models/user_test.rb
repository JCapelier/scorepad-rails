require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Associations
  should have_one(:avatar_attachment)
  should have_one(:avatar_blob)
  should have_many(:session_players)
  should have_many(:game_sessions)

  # Validations
  should validate_presence_of(:email)
  should validate_presence_of(:email)
  should validate_presence_of(:password)
  should validate_presence_of(:password)
  should validate_presence_of(:username)
  should validate_length_of(:password).is_at_least(6).is_at_most(128)
  should validate_length_of(:password).is_at_least(6)
  should validate_length_of(:username).is_at_least(3).is_at_most(20)
  should validate_uniqueness_of(:email)
  should validate_uniqueness_of(:email).case_insensitive
  should validate_uniqueness_of(:username).case_insensitive
  should validate_uniqueness_of(:reset_password_token)

  # Sanity build (ensures factory/quick create works)
  test "factory builds a valid User" do
    record = defined?(FactoryBot) ? build(:user) : User.new
    assert record.valid?, record.errors.full_messages.to_sentence
  end
end
