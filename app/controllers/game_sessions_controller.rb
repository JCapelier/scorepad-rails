class GameSessionsController < ApplicationController
  def create
    game = Game.find(params[:game_session][:game_id])
    session = GameSession.new(session_params.merge(starts_at: Time.current, status: "pending"))
    session.game = game


    if session.save
      redirect_to seating_game_session_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def session_params
    params.require(:game_session).permit(:number_of_players, :location)
  end
end
