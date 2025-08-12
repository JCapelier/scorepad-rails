class Game < ApplicationRecord
  has_many :game_sessions, dependent: :destroy

  def game_engine
    case title.downcase
    when "five crowns"
      Games::FiveCrowns
    when "skyjo"
      Games::Skyjo
    when "mexican train"
      Games::MexicanTrain
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

  def stats_service
    case title.downcase
    when "five crowns"
      Games::FiveCrownsStatsService
    when "skyjo"
      Games::SkyjoStatsService
    when "mexican train"
      Games::MexicanTrainStatsService
    else
      raise "Unknown game: #{title}"
    end
  end
end
