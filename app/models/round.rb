class Round < ApplicationRecord
  validates :status, inclusion: { in: %w[pending active completed], message: "Status must be pending, active, or completed" }
  belongs_to :scoresheet
  delegate :game_session, to: :scoresheet
  delegate :session_players, to: :scoresheet
  has_many :moves

  def move_for_first_finisher
    moves.find_by(move_type: "first_finisher")
  end
end
