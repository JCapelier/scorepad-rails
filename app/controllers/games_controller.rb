class GamesController < ApplicationController
  def show
    @game = Game.find(params[:id])
    @game_session = GameSession.new
    @game.min_players.times {SessionPlayer.new}
  end
end
