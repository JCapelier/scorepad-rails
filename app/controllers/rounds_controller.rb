class RoundsController < ApplicationController
  def update
    round = Round.find(params[:id])
    authorize round
    scoresheet = round.scoresheet
    game_engine = round.scoresheet.game_session.game.game_engine
    round.data ||= {}

    if params[:phase] && params[:phase] == "bidding"
      results = game_engine.handle_bidding_phase(round, params)

    else
      results = game_engine.handle_round_completion(round, params)
      if results[:error]
        flash[:alert] = results[:error]
        redirect_to scoresheet_path(round.scoresheet)
        return
      else
        unless round.status == "completed"
          round.update(status: "completed")
        end
      end
    end


    case results[:instruction]
      when "go_to_next_round"
        unless round.scoresheet.rounds.all? { |round| round.status == "completed"}
          new_round = round.scoresheet.rounds.where(status: "pending").order(:round_number).first
          new_round.update(status: "active") if new_round
        end
      when "create_next_round"
        next_round_number = round.round_number + 1
        new_round = round.scoresheet.rounds.find_by(round_number: next_round_number)
        unless new_round
          new_round = Round.create(scoresheet: scoresheet, round_number: next_round_number, status: "active", data: results[:next_round_data])
        end
      when "end_game"
        round
    end


    round.data.merge!(results[:round_data_updates])
    round.save
    game_name = scoresheet.game_session.game.title.underscore
    if game_name == 'oh_hell' && params[:phase] == 'bidding'
      Move.where(round_id: round.id).destroy_all
    elsif game_name == 'oh_hell'
      Move.where(round_id: round.id, move_type: 'tricks').destroy_all
    else
      Move.where(round_id: round.id).destroy_all
    end

    Move.create(results[:move_data]) if results[:move_data].present?
    results[:move_data_list].each { |move_attrs| Move.create(move_attrs) } if results[:move_data_list].present?

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
