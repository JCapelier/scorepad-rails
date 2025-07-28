class GameSessionsController < ApplicationController
  def create
    game = Game.find(params[:game_session][:game_id])
    session = GameSession.new(session_params.merge(starts_at: Time.current, status: "pending"))
    session.game = game


    if session.save
      redirect_to seating_game_session_path(session)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def new
    @game = Game.find(params[:game_id])
    @session = GameSession.new
    @users = User.all
  end


  def create
    game = Game.find(params[:game_session][:game_id])
    session = GameSession.new(session_params)
    session.starts_at = Time.current
    session.save!
    if session.save
      redirect_to scoresheet_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def session_params
    params.require(:game_session).permit(:location, :game_id, session_players_attributes: [:user_id, :position])
  end
end
