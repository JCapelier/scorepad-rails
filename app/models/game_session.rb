class GameSession < ApplicationRecord
  belongs_to :game
  has_many :session_players, dependent: :destroy
  has_one :score_sheet, dependent: :destroy

  accepts_nested_attributes_for :session_players
end
