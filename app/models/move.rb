class Move < ApplicationRecord
  belongs_to :session_player
  belongs_to :round
end
