class Game < ApplicationRecord
  has_many :game_sessions, dependent: :destroy

  def service_class
    case title.downcase
    when "five crowns"
      Games::FiveCrowns
    else
      raise "Unknown game: #{title}"
    end
  end

  def max_players
    service_class.max_players
  end

  def min_players
    service_class.min_players
  end
end
