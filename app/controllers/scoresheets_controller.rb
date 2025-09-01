class ScoresheetsController < ApplicationController
  def show
    @scoresheet = Scoresheet.find(params[:id])
    @rounds = @scoresheet.rounds.order(:round_number)
    @current_round = @rounds.find_by(status: "active") || @rounds.find_by(status: "pending") || @rounds.last

    @rounds_json = @rounds.map { |round| round.data.merge("round_number" => round.round_number) }.to_json

    @totals = @scoresheet.game_session.game.game_engine.calculate_total_scores(@scoresheet)
    @score_limit = @scoresheet.data["score_limit"] if @scoresheet.data["score_limit"]
  end

  def results
    @scoresheet = Scoresheet.find(params[:id])
    @scoresheet.game_session.update(status: "completed", ends_at: Time.current)
    game = @scoresheet.game_session.game
    @trophies = game.game_engine.trophies(@scoresheet)
    @leaderboard = game.game_engine.leaderboard(@scoresheet)
    # leaderboard return names instead of players
    winner_name = @leaderboard.first[:player]
    # The string is either sp.user.username or sp.guest_name
    winner_session_player = @scoresheet.game_session.session_players.detect { |sp| sp.display_name == winner_name }
    # Create a win move, for stats purpose.
    Move.create!(round: @scoresheet.rounds.last, session_player: winner_session_player, move_type: "win")

    respond_to do |format|
      format.html # renders results.html.erb as usual
      format.any { render :results, layout: true } # fallback for other formats (e.g., turbo_stream)
    end
  end

end
