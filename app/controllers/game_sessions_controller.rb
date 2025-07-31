class GameSessionsController < ApplicationController

  def new
    @game = Game.find(params[:game_id])
    @session = GameSession.new
    @users = User.all

    custom_rules_config = YAML.load_file(Rails.root.join("config/games/custom_rules.yml"))
    @custom_rules = custom_rules_config[@game.title.downcase.tr(' ', '_')]
  end

  def create
    game = Game.find(params[:game_session][:game_id])
    session = GameSession.new(session_params)
    session.starts_at = Time.current
    session.status = "active"
    if session.save
      custom_rules = params[:custom_rules] || {}
      init_data = game.game_engine.initial_data(session.session_players, custom_rules)
      scoresheet = Scoresheet.create(game_session: session, data: init_data.except("config"))
      rounds_info = game.game_engine.round_data(session.session_players, init_data["config"] )
      rounds_info.each_with_index do |round_hash, i|
        Round.create(scoresheet: scoresheet, round_number: i + 1, data: round_hash, status: "pending")
      end
      redirect_to scoresheet_path(scoresheet)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def session_params
    params.require(:game_session).permit(:location, :game_id, session_players_attributes: [:user_id, :position])
  end
end
