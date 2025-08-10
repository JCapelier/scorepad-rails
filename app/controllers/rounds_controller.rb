class RoundsController < ApplicationController
  def update
    round = Round.find(params[:id])
    scoresheet = round.scoresheet
    rounds = scoresheet.rounds.order(:round_number)
    game_engine = round.scoresheet.game_session.game.game_engine
    results = game_engine.handle_round_completion(round, params)

    if results[:error]
      flash[:alert] = results[:error]
      redirect_to scoresheet_path(round.scoresheet)
      return
    end

    unless round.status == "completed"
      round.update(status: "completed")
    end

    case results[:instruction]
      when "go_to_next_round"
        unless round.scoresheet.rounds.all? { |round| round.status == "completed"}
          new_round = round.scoresheet.rounds.where(status: "pending").order(:round_number).first
          new_round.update(status: "active") if new_round
        end
      when "create_next_round"
        new_round = Round.create(scoresheet: scoresheet, round_number: round.round_number + 1, status: "active", data: results[:next_round_data])
      when "end_game"
        round
    end


    round.data ||= {}
    round.data.merge!(results[:round_data_updates])
    round.save
    Move.where(round_id: round.id).destroy_all
    Move.create(results[:move_data]) if results[:move_data].present?
    if results[:move_data_list].present?
      results[:move_data_list].each { |move_attrs| Move.create(move_attrs) }
    end

    game_name = scoresheet.game_session.game.title.underscore
    respond_to do |format|
      format.json {
        render json: {
          success: true,
          round_html: render_to_string(
            partial: "scoresheets/#{game_name}_round_info",
            formats: [:html],
            locals: { round: new_round || round }
          ),
          scoresheet_html: render_to_string(partial: "scoresheets/#{game_name}_scoresheet", formats: [:html], locals: { scoresheet: scoresheet })
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
