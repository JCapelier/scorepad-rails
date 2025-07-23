class Round < ApplicationRecord
  belongs_to :score_sheet
  delegate :game_session, to: :score_sheet
  delegate :session_players, to: :score_sheet
end
