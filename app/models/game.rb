class Game < ApplicationRecord
  has_many :game_sessions, dependent: :destroy

  def game_engine
    case title.downcase
    when "five crowns"
      Games::FiveCrowns
    else
      raise "Unknown game: #{title}"
    end
  end

  def max_players
    game_engine.max_players
  end

  def min_players
    game_engine.min_players
  end
end
