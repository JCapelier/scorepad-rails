class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :session_players, dependent: :destroy

  has_one_attached :avatar

  def avatar_url
    if avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_url(avatar, only_path: true)
    else
      ActionController::Base.helpers.asset_path("default-avatar.jpg")
    end
  end

  def completed_games_count
  GameSession.joins(:session_players)
    .where(session_players: { user_id: id }, status: "completed")
    .count
  end

  def games_won_count
    GameSession.joins(:session_players)
      .where(session_players: { user_id: id }, status: "completed")
      .select { |gs|
        gs.scoresheet &&
        begin
          leaderboard = gs.game.game_engine.leaderboard(gs.scoresheet)
          leaderboard.present? && leaderboard.first[0] == self.username
        end
      }
      .count
  end

  def victory_percent
    total = completed_games_count
    total > 0 ? (games_won_count * 100 / total) : 0
  end
end

