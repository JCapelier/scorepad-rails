module ScoresheetHelper
  # Returns a CSS style string for a score cell based on game logic
  def default_score_cell_style(is_first, finish_status)
    style = 'padding:8px; text-align:center; cursor:pointer; background:#fafafa;'
    if is_first && finish_status == 'failure'
      style += ' color: red; font-weight: bold;'
    elsif is_first
      style += ' color: purple; font-weight: bold;'
    end
    style
  end

  def set_round_info(round)
    case round.scoresheet.game_session.game.title
    when 'Skyjo'
      {
        'Round:' => round.round_number,
        'Dealer' => round.data['dealer']
      }
    when 'Five Crowns'
      {
        'Round:' => round.round_number,
        'Dealer:' => round.data['dealer'],
        'First player:' => round.data['first_player'],
        'Number of cards:' => round.data['cards_per_round'],
        'Wild cards:' => round.data['wild_cards'] != round.data['cards_per_round'] ? round.data['wild_cards'] : nil
      }
    when 'Mexican Train'
      {
        'Round:' => round.round_number,
        'Starting domino:' => round.data['starting_domino'],
        'First player:' => assign_first_player_for_round(round.scoresheet, round.round_number)
      }
    when 'Oh Hell'
      {
        'Round:' => round.round_number,
        'Dealer:' => round.data['dealer'],
        'First player:' => round.data['first_player'],
        'Number of cards:' => round.data['cards_per_round'] != round.round_number ? round.data['cards_per_round'] : nil
      }
    end
  end

  def assign_first_player_for_round(scoresheet, round_number)
    if round_number == 1
      'Fight amongst yourselves!'
    else
      previous_round = scoresheet.rounds.find_by(round_number: round_number - 1)
      previous_round&.move_for_finisher&.session_player&.display_name
    end
  end

  def scoresheet_in_progress?(scoresheet)
    case scoresheet.game_session.game.title
    when 'Skyjo'
      scoresheet.game_session.game.game_engine.calculate_total_scores(@scoresheet).values.all? { |score| score < scoresheet.data['score_limit'] }
    when 'Five Crowns', 'Mexican Train', 'Oh Hell'
      scoresheet.rounds.any? { |round| round.status == 'pending' || round.status == 'active' }
    end
  end

  def player_total(scoresheet, player)
    scoresheet.rounds.order(:round_number).sum do |round|
      round.data.dig('scores', player.display_name).to_i
    end
  end

  def editable_cell?(round)
    round.status == 'completed'
  end

  def scoresheet_cell_attributes(scoresheet, round)
    case scoresheet.game_session.game.title
    when 'Skyjo'
      {
        'data-first-finisher' => round.data['first_finisher'],
        'data-finish-status' => round.move_for_first_finisher&.data&.dig('finish_status'),
        'data-child-mode' => scoresheet.data['child_mode']['value']
      }
    when 'Five Crowns'
      {
        'data-first-finisher' => round.data['first_finisher'],
        'data-finish-status' => round.move_for_first_finisher&.data&.dig('finish_status'),
        'data-early-finish' => scoresheet.data['early_finish']['value']
      }
    when 'Mexican Train'
      {
        'data-first-finisher' => round.data['first_finisher']
      }

    end
  end

  def dual_columns_scoresheet_cell_attributes(scoresheet, round, session_player, cell_type)
    case scoresheet.game_session.game.title
    when 'Oh Hell'
      {
        'data-round-id' => round.id,
        'data-round-phase' => round.data['phase'],
        'data-round-status' => round.status,
        'data-round-number' => round.round_number,
        'data-cards-per-round' => round.data['cards_per_round'],
        'data-first-player' => round.data['first_player'],
        'data-tricks' => round.data['tricks'].to_json,
        'data-player' => session_player.display_name,
        "data-#{cell_type}" => round.data.dig("#{cell_type}s", session_player.display_name),
        'data-oh-hell-target' => "'#{cell_type}'-cell"
      }
    end
  end

  def set_ordered_players(scoresheet, round)
    players = scoresheet.game_session_players.to_a
    first_player = round.data['first_player']
    first_player_index = players.index { |player| player.display_name == first_player }
    players.rotate(first_player_index)
  end
end
