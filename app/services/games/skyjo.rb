
module Games
  class Skyjo < Games::Shared::GameBase

    def self.ascending_scoring?
      true
    end

    def self.include_first_finisher?
      true
    end

    def self.initial_data(players, custom_rules = {})
      data = super(players, custom_rules)
      config = data['config']

      config['child_mode']['value'] = true if custom_rules['child_mode'] && custom_rules['child_mode']['value'] == 'true'

      if custom_rules['custom_score_limit'] && custom_rules['custom_score_limit']['value'].present?
        config['custom_score_limit']['value'] = true
        config['score_limit'] = custom_rules['custom_score_limit']['value'].to_i
      end

      data.merge({
        'score_limit' => config['score_limit'],
        'child_mode' => config['child_mode'],
        'custom_score_limit' => config['custom_score_limit']
      })
    end

    def self.round_data(players, config)
      ordered_players = players.sort_by(&:position)
      dealer = ordered_players.last

      [
        'dealer' => dealer.display_name
      ]
    end

    def self.set_first_finish_status(round, scores, first_finisher)
      # Child mode implies that the finish status is nil, because irrelevant
      return if round.scoresheet.data['child_mode']['value'] == true

      first_score = scores[first_finisher].to_i
      other_scores = scores.reject { |player, _| player == first_finisher }.values.map(&:to_i)
      if other_scores.all? { |score| first_score < score }
        'success'
      else
        scores[first_finisher] = first_score * 2
        'failure'
      end
    end

    def self.handle_round_completion(round, params)
      scores = params[:scores]
      first_finisher = params[:first_finisher]

      finish_status = set_first_finish_status(round, scores, first_finisher)

      session_player = round.scoresheet.game_session.session_players.find_by(user: User.find_by(username: first_finisher))
      move_data = { round: round,
                    session_player: session_player,
                    move_type: 'first_finisher',
                    data: round.scoresheet.data['child_mode']['value'] == false ? { finish_status: finish_status } : { finish_status: nil } }
      # totals = calculate_total_scores(round.scoresheet)
      # I need to figure out if I calculate totals in the back or the front, once and for all

      # For Skyjo, I need to figure out if a player is going to reach the score limit in advance, to decide
      # if I should ask the controller to create another round or not
      projected_totals = projected_totals(round.scoresheet, round, scores)
      score_limit = round.scoresheet.data['score_limit']

      projected_totals.values.any? { |projected_total| projected_total >= score_limit } ? instruction = 'end_game' : instruction = 'create_next_round'

      {
        instruction: instruction,
        round_data_updates: { 'scores' => scores, 'first_finisher' => first_finisher },
        move_data: move_data,
        next_round_data: next_round_data(round)
      }
    end

    def self.next_round_data(round)
      players = round.scoresheet.game_session.session_players.order(:position)
      current_dealer = round.data['dealer']
      ordered_players = players.sort_by(&:position)
      usernames = ordered_players.map(&:display_name)
      dealer_index = usernames.index(current_dealer)
      next_dealer = usernames[(dealer_index + 1) % usernames.size]

      {
        'dealer' => next_dealer
      }
    end

    def self.projected_totals(scoresheet, current_round, incoming_scores)
      totals = calculate_total_scores(scoresheet)

      old_scores = current_round.data['scores'] || {}
      # The point is to avoid counting an old scores twice (which are taken into account in calculate_total_scores) in case of an edit. That's why we substract them.
      old_scores.each { |player, score| totals[player] -= score.to_i }

      incoming_scores.each { |player, score| totals[player] += score.to_i }

      totals
    end

    # This gets the stats for the game session, which will be set as data for the session player.
    # Larger scales stats are not processed in this service.
    def self.player_stats(scoresheet)
      # These five first lines are almost identical for every game, except the ascendant parameter. It needs refacto.
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
          total_score: scores_by_player[player],
          rank: ranks_by_player[player],
          average_score: session_stats_service.average_score_per_round(rounds, players)[player],
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
