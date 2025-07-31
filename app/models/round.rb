class Round < ApplicationRecord
  belongs_to :scoresheet
  delegate :game_session, to: :scoresheet
  delegate :session_players, to: :scoresheet
end
