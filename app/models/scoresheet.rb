class Scoresheet < ApplicationRecord
  belongs_to :game_session
  has_many :rounds, dependent: :destroy
  has_many :session_players, through: :game_session
  has_one :game, through: :game_session
  has_many :moves, through: :rounds
end
