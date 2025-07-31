class ScoresheetsController < ApplicationController
  def show
    @scoresheet = Scoresheet.find(params[:id])
    @rounds = @scoresheet.rounds.order(:round_number)
    @current_round = @rounds.find_by(status: "active") || @rounds.first
    @current_round.update(status: "active") if @current_round.status != "active"
    @rounds_json = @rounds.map { |round| round.data.merge("round_number" => round.round_number) }.to_json
  end

  def update
    scoresheet = Scoresheet.find(params[:id])
    scoresheet.update(status: "completed")

    redirect_to results_scoresheet_path(scoresheet)
  end
end
