class Move < ApplicationRecord
  validates :move_type, inclusion: { in: %w[first_finisher bid tricks], message: "Move type must be first_finisher, bid, or tricks" }
  belongs_to :session_player
  belongs_to :round
end
