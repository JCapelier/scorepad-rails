class RoundsController < ApplicationController
  def update
    round = Round.find(params[:id])
    game_engine = round.scoresheet.game_session.game.game_engine
    result = game_engine.handle_round_completion(round, params)

    if result[:error]
      flash[:alert] = result[:error]
      redirect_to scoresheet_path(round.scoresheet)
      return
    end

    unless round.status == "completed"
      round.update(status: "completed")
      unless round.scoresheet.rounds.all? { |round| round.status == "completed"}
        new_round = round.scoresheet.rounds.where(status: "pending").order(:round_number).first
        new_round.update(status: "active") if new_round
      end
    end

    round.data ||= {}
    round.data.merge!(result[:round_data_updates])
    round.save
    Move.where(round_id: round.id).destroy_all
    Move.create(result[:move_data]) if result[:move_data].present?
    if result[:move_data_list].present?
      result[:move_data_list].each { |move_attrs| Move.create(move_attrs) }
    end

    scoresheet = round.scoresheet
    rounds = Round.where(scoresheet: scoresheet, status: 'completed')
    game_engine.calculate_total_scores(rounds)


    respond_to do |format|
      format.json {
        render json: {
          success: true,
          round_html: render_to_string(
            partial: "scoresheets/five_crowns_round_info",
            formats: [:html],
            locals: { round: new_round || round }
          ),
          scoresheet_html: render_to_string(partial: "scoresheets/five_crowns_scoresheet", formats: [:html], locals: { scoresheet: scoresheet })
        }
      }
      format.html { redirect_to scoresheet_path(scoresheet), notice: "Round updated." }
      format.turbo_stream { head :ok }
    end
  end

  private

  def round_params
    params.permit(:first_finisher, :move_type, scores: {})
  end
end
