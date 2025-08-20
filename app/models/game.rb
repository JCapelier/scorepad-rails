class Game < ApplicationRecord
  has_many :game_sessions, dependent: :destroy

  def game_engine
    "Games::#{title.delete(" ").camelize}".constantize
  end

  def max_players
    game_engine.max_players
  end

  def min_players
    game_engine.min_players
  end

  def stats_service
    "Games::#{title.delete(" ").camelize}StatsService".constantize
  end
end
