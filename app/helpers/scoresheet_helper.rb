module ScoresheetHelper
  # Returns a CSS style string for a score cell based on game logic
  def skyjo_score_cell_style(is_first, finish_status)
    style = "padding:8px; text-align:center; cursor:pointer; background:#fafafa;"
    if is_first && finish_status == "failure"
      style += " color: red; font-weight: bold;"
    elsif is_first
      style += " color: purple; font-weight: bold;"
    end
    style
  end

  def scoresheet_in_progress?(scoresheet)
    case scoresheet.game_session.game.title
    when "Skyjo"
      scoresheet.game_session.game.game_engine.calculate_total_scores(@scoresheet).values.all? { |score| score < scoresheet.data["score_limit"] || 100 }
    end
  end

  def player_total(scoresheet, player)
    scoresheet.rounds.order(:round_number).sum do |round|
      round.data.dig("scores", player.display_name).to_i
    end
  end

  def editable_cell?(round)
    round.status == "completed"
  end

  def scoresheet_cell_attributes(scoresheet, round, player)
    case scoresheet.game_session.game.title
    when "Skyjo"
      {
        'data-first-finisher' => round.data['first_finisher'],
        'data-finish-status' => round.move_for_first_finisher&.data&.dig('finish_status'),
        'data-child-mode' => scoresheet.data["child_mode"]
      }
    end
  end
end
