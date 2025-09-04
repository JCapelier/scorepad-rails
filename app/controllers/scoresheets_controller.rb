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
    @leaderboard = game.game_engine.leaderboard(@scoresheet)
    @stats = game.game_engine.player_stats(@scoresheet)
    players = @scoresheet.game_session.session_players

    players.each do |player|
      player_stats = @stats[player.display_name]
      player.update(data: player_stats)
    end

    respond_to do |format|
      format.html # renders results.html.erb as usual
      format.any { render :results, layout: true } # fallback for other formats (e.g., turbo_stream)
    end
  end

end
