class ScoresheetsController < ApplicationController
  def show
    @scoresheet = Scoresheet.find(params[:id])
    @rounds = @scoresheet.rounds.order(:round_number)
    @current_round = @rounds.find_by(status: "active") || @rounds.find_by(status: "pending") || @rounds.last

    @totals = @scoresheet.game_session.game.game_engine.calculate_total_scores(@scoresheet)
    @score_limit = @scoresheet.data["score_limit"] if @scoresheet.data["score_limit"]
  end

  def results
    @scoresheet = Scoresheet.find(params[:id])
    @scoresheet.game_session.update(status: "completed", ends_at: Time.current)
    game = @scoresheet.game_session.game
    ascending = game.game_engine.ascending_scoring?
    @leaderboard = game.game_engine.leaderboard(@scoresheet, ascending)
    puts "Leaderboard ascending: #{ascending}"
    winner_username = @leaderboard.select { |player| player[:rank] == 1 }
    @scoresheet.data['winner_username'] = winner_username

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
