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
  end

end
