module Games
  class FiveCrowns < Games::Shared::GameBase

    def self.initial_data(players, custom_rules = {})
      data = super(players, custom_rules)
      config = data['config']

      if custom_rules['long_game'] && custom_rules['long_game']['value'] == 'true'
        config['number_of_rounds'] = 21
        config['long_game'] = { 'value' => true }
      end

      config['early_finish']['value'] = true if custom_rules.dig('early_finish', 'value') == 'true'

      if custom_rules.dig('early_finish', 'subrules', 'double_if_not_lowest') == 'true'
        config['early_finish']['subrules']['double_if_not_lowest'] = true
      end

      data.merge({
        'number_of_rounds' => config['number_of_rounds'],
        'early_finish' => config['early_finish'],
        'long_game' => config['long_game']
        })
    end

    def self.round_data(players, config)
      ordered_players = players.sort_by(&:position)
      number_of_players = ordered_players.size

      (1..config['number_of_rounds']).map do |round_number|
        first_player_index = (round_number - 1) % number_of_players
        dealer_index = (first_player_index - 1) % number_of_players

        first_player = ordered_players[first_player_index]
        dealer = ordered_players[dealer_index]

        {
          'cards_per_round' => config['cards_per_round'][round_number],
          'wild_cards' => config['wild_cards'][round_number],
          'first_player' => first_player.display_name,
          'dealer' => dealer.display_name
        }
      end
    end

    def self.handle_round_completion(round, params)
      scores = params[:scores]
      first_finisher = params[:first_finisher]
      early_finish_data = round.scoresheet.data['early_finish'] || {}
      early_finish_disabled = early_finish_data['value'] == false
      double_if_not_lowest_raw = early_finish_data.dig('subrules', 'double_if_not_lowest')
      double_if_not_lowest = double_if_not_lowest_raw == true || double_if_not_lowest_raw == 'true'
      first_score = scores[first_finisher].to_i if scores && first_finisher

      if early_finish_disabled && first_score != 0
        return { error: 'First finisher must have score 0 unless early finish is enabled.' }
      end

      finish_status = nil
      if double_if_not_lowest && scores && first_finisher
        first_score = scores[first_finisher].to_i
        other_scores = scores.reject { |player, _| player == first_finisher }.values.map(&:to_i)
        if other_scores.all? { |score| first_score < score }
          finish_status = 'success'
        else
          scores[first_finisher] = first_score * 2
          finish_status = 'failure'
        end
      end

      session_player = round.scoresheet.game_session.session_players.find_by(user: User.find_by(username: first_finisher))
      move_data = { round: round, session_player: session_player, move_type: 'first_finisher', data: {} }
      move_data[:data][:finish_status] = finish_status if finish_status
      {
        instruction: 'go_to_next_round',
        round_data_updates: { 'scores' => scores, 'first_finisher' => first_finisher },
        move_data: move_data
      }
    end

    def self.player_stats(scoresheet)
      rounds = scoresheet.rounds.order(:round_number)
      players = scoresheet.game_session.session_players.map(&:display_name)

      leaderboard = self.leaderboard(scoresheet, ascending: true)
      scores_by_player = leaderboard.to_h { |entry| [entry[:player], entry[:score]] }
      ranks_by_player = leaderboard.to_h { |entry| [entry[:player], entry[:rank]] }

      finisher_stats = session_stats_service.first_finisher_stats(rounds, players)
      score_extremes = session_stats_service.lowest_and_highest_scores(rounds, players)
      average_scores = session_stats_service.average_score_per_round(rounds, players)

      stats = {}
      players.each do |player|
        stats[player] = {
          total_score: scores_by_player[player],
          rank: ranks_by_player[player],
          average_score: session_stats_service.average_scores[player],
          first_finisher_count: finisher_stats[player][:first_finisher_count],
          finish_success: finisher_stats[player][:finish_success],
          finish_failure: finisher_stats[player][:finish_failure],
          finish_ratio: finisher_stats[player][:finish_ratio],
          rounds_with_the_lowest_score: score_extremes[player][:lowest_score_rounds],
          lowest_score_in_a_round: score_extremes[player][:lowest_score],
          highest_score_in_a_round: score_extremes[player][:highest_score]
        }
      end
      stats
    end
  end
end
