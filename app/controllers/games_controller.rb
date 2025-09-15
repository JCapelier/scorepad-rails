class GamesController < ApplicationController
  def show
    @game = Game.find(params[:id])
    authorize @game
    @game_session = GameSession.new
    @game.min_players.times {SessionPlayer.new}
    @active_sessions = @game.game_sessions.joins(:session_players).where(status: "active", session_players: { user_id: current_user.id })
  end
end
