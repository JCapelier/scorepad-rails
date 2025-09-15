class GameSession < ApplicationRecord
  validates :status, inclusion: { in: %w[pending active completed], message: "Status must be pending, active, or completed" }
  belongs_to :game
  has_many :session_players, dependent: :destroy
  has_one :scoresheet, dependent: :destroy

  accepts_nested_attributes_for :session_players
end
