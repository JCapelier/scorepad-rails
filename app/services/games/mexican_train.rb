module Games
  class MexicanTrain < Games::Shared::GameBase

    def self.ascending_scoring?
      true
    end

    def self.include_first_finisher?
      true
    end

    def self.initial_data(players, custom_rules = {})
      data = super(players, custom_rules)
      config = data['config']

      if custom_rules['long_game'] && custom_rules['long_game']['value'] == 'true'
        config['number_of_rounds'] = 25
        config['long_game'] = { 'value' => true }
      end

      data.merge({
        'number_of_rounds' => config['number_of_rounds'],
        'long_game' => config['long_game']
      })
    end

    def self.starting_domino(round_number)
      domino = 12 - ((round_number - 1) % 13)
      domino == 12 ? "Double #{domino}" : 'Double white'
    end

    def self.round_data(players, config)
      ordered_players = players.sort_by { |player| player.position }
      number_of_players = ordered_players.size

      (1..config['number_of_rounds']).map do |round_number|
        first_player_index = (round_number - 1) % number_of_players
        dealer_index = (first_player_index - 1) % number_of_players

        first_player = ordered_players[first_player_index]
        domino = starting_domino(round_number)

        {
          'starting_domino' => starting_domino(round_number),
          'first_player' => first_player.display_name,
          'starting_domino' => domino
        }
      end
    end

    def self.handle_round_completion(round, params)
      scores = params[:scores]
      first_finisher = params[:first_finisher]
      first_score = scores[first_finisher].to_i if scores && first_finisher

      if first_score != 0
        return { error: 'First finisher must have a score of 0' }
      end

      session_player = round.scoresheet.game_session.session_players.find_by(user: User.find_by(username: first_finisher))
      move_data = { round: round, session_player: session_player, move_type: 'first_finisher', data: {} }

      {
        instruction: 'go_to_next_round',
        round_data_updates: { 'scores' => scores, 'first_finisher' => first_finisher },
        move_data: move_data
      }
    end

    def self.player_stats(scoresheet)
      rounds = scoresheet.rounds.order(:round_number)
      players = scoresheet.game_session.session_players.map(&:display_name)
      ascending = scoresheet.game.game_engine.ascending_scoring?
      leaderboard = self.leaderboard(scoresheet, ascending)
      scores_by_player = leaderboard.to_h { |entry| [entry[:player], entry[:score]] }
      ranks_by_player = leaderboard.to_h { |entry| [entry[:player], entry[:rank]] }

      finisher_stats = session_stats_service.first_finisher_stats(rounds, players)
      score_extremes = session_stats_service.lowest_and_highest_scores(rounds, players)
      average_scores = session_stats_service.average_score_per_round(rounds, players)

      stats = {}
      players.each do |player|
        stats[player] = {
          rank: ranks_by_player[player],
          total_score: scores_by_player[player],
          average_score_per_round: session_stats_service.average_scores_per_round(rounds, players)[player],
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
