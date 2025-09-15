class GameSessionsController < ApplicationController

  def new
    @game = Game.find(params[:game_id])
    @session = GameSession.new
    authorize @session
    @users = User.all

    custom_rules_config = YAML.load_file(Rails.root.join("config/games/custom_rules.yml"))
    @custom_rules = custom_rules_config[@game.title.downcase.tr(' ', '_')]
  end

  def create
    @game = Game.find(params[:game_session][:game_id])
    @session = GameSession.new(session_params)
    authorize @session
    @session.starts_at = Time.current
    @session.status = "active"
    if @session.save
      Rails.logger.debug @session.errors.full_messages.inspect
      custom_rules = params[:custom_rules] || {}
      init_data = @game.game_engine.initial_data(@session.session_players, custom_rules)
      scoresheet = Scoresheet.create(game_session: @session, data: init_data.except("config"))
      rounds_info = @game.game_engine.round_data(@session.session_players, init_data["config"] )
      rounds_info.each_with_index do |round_hash, i|
        Round.create(scoresheet: scoresheet, round_number: i + 1, data: round_hash, status: "pending")
      end
      redirect_to scoresheet_path(scoresheet)
    else
      Rails.logger.debug @session.errors.full_messages.inspect
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session = GameSession.find(params[:id])
    authorize session
    game = session.game
    session.destroy
    @active_sessions = game.game_sessions.where(status: 'active').joins(:session_players).where(session_players: { user_id: current_user.id }).distinct

    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace('active_sessions_frame', partial: 'games/active_sessions', locals: { active_sessions: @active_sessions })
      }
      format.html { redirect_to game_path(game), notice: "Game session deleted." }
    end
  end


  private

  def session_params
    params.require(:game_session).permit(:location, :game_id, session_players_attributes: [:user_id, :guest_id, :guest_name, :position])
  end
end
