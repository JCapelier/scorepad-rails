
module Games
  class Skyjo

    def self.initial_data(players, custom_rules = {})
      config = YAML.load_file(Rails.root.join('config/games/skyjo.yml'))

      config['child_mode'] = true if custom_rules['child_mode'] && custom_rules['child_mode']['value'] == 'true'

      if custom_rules['custom_score_limit'] && custom_rules['custom_score_limit']['value'].present?
        config['custom_score_limit'] = true
        config['score_limit'] = custom_rules['custom_score_limit']['value'].to_i
      end

      {
        'config' => config,
        'score_limit' => config['score_limit'],
        'players' => players,
        'total_scores' => players.to_h { |player| [player, 0] },
        'child_mode' => config['child_mode'],
        'custom_score_limit' => config['custom_score_limit']
      }
    end

    def self.max_players
      config = YAML.load_file(Rails.root.join('config/games/skyjo.yml'))
      config['max_players']
    end

    def self.min_players
      config = YAML.load_file(Rails.root.join('config/games/skyjo.yml'))
      config['min_players']
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
      return if round.scoresheet.data['child_mode'] == true

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

      first_score = scores[first_finisher].to_i if scores && first_finisher

      finish_status = set_first_finish_status(round, scores, first_finisher)

      session_player = round.scoresheet.game_session.session_players.find_by(user: User.find_by(username: first_finisher))
      move_data = { round: round,
                    session_player: session_player,
                    move_type: 'first_finisher',
                    data: { finish_status: finish_status } }
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

    def self.calculate_total_scores(scoresheet)
      rounds = scoresheet.rounds.order(:round_number)
      totals = Hash.new(0)
      rounds.each do |round|
        scores = round.data['scores'] || {}
        scores.each do |player, score|
          totals[player] += score.to_i
        end
      end
      totals
    end

    def self.projected_totals(scoresheet, current_round, incoming_scores)
      totals = calculate_total_scores(scoresheet)

      old_scores = current_round.data['scores'] || {}
      # The point is to avoid counting an old scores twice (which are taken into account in calculate_total_scores) in case of an edit. That's why we substract them.
      old_scores.each { |player, score| totals[player] -= score.to_i }

      incoming_scores.each { |player, score| totals[player] += score.to_i }

      totals
    end

    def self.leaderboard(scoresheet)
      total_scores = calculate_total_scores(scoresheet)
      # Sort by score ascending (lower is better in Skyjo)
      sorted = total_scores.sort_by { |_, score| score.to_i }
      leaderboard = []
      prev_score = nil
      prev_rank = 0
      count = 0
      sorted.each do |player, score|
        count += 1
        # The next line deal with ex aequo
        rank = score == prev_score ? prev_rank : count
        leaderboard << { player: player, score: score, rank: rank }
        prev_score = score
        prev_rank = rank
      end
      leaderboard
    end

    def self.player_stats(scoresheet)
      rounds = scoresheet.rounds.order(:round_number)
      players = scoresheet.game_session.session_players.map(&:display_name)

      leaderboard = self.leaderboard(scoresheet)
      scores_by_player = leaderboard.to_h { |entry| [entry[:player], entry[:score]] }
      ranks_by_player = leaderboard.to_h { |entry| [entry[:player], entry[:rank]] }

      finisher_stats = first_finisher_stats(rounds, players)
      score_extremes = lowest_and_highest_scores(rounds, players)
      average_scores = average_score_per_round(rounds, players)

      stats = {}
      players.each do |player|
        stats[player] = {
          total_score: scores_by_player[player],
          rank: ranks_by_player[player],
          average_score: average_scores[player],
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

    def self.average_score_per_round(rounds, players)
      total_rounds = rounds.last&.round_number
      scoresheet = rounds.first&.scoresheet
      leaderboard = scoresheet ? self.leaderboard(scoresheet) : []
      averages = {}
      leaderboard.each do |entry|
        averages[entry[:player]] = (entry[:score].to_f / total_rounds).round(2)
      end
      averages
    end

    def self.first_finisher_stats(rounds, players)
      stats = {}
      players.each do |player|
        stats[player] = { first_finisher_count: 0, finish_success: 0, finish_failure: 0, finish_ratio: 0.0 }
      end
      rounds.each do |round|
        move = round.move_for_first_finisher
        finish_status = move&.data&.dig('finish_status')
        first_finisher = move&.session_player&.display_name
        players.each do |player|
          if player == first_finisher
            stats[player][:first_finisher_count] += 1
            if finish_status == 'success'
              stats[player][:finish_success] += 1
            elsif finish_status == 'failure'
              stats[player][:finish_failure] += 1
            end
          end
        end
      end
      players.each do |player|
        # If child mode is enable, first_finisher_count will progress without relation to a success ratio.
        total = stats[player][:finish_success] + stats[player][:finish_failure]
        stats[player][:finish_ratio] = total > 0 ? (stats[player][:finish_success].to_f / total).round(2) : nil
      end
      stats
    end

    def self.lowest_and_highest_scores(rounds, players)
      stats = {}
      players.each do |player|
        stats[player] = { lowest_score_rounds: 0, lowest_score: nil, highest_score: nil }
      end
      rounds.each do |round|
        scores = round.data['scores'] || {}
        min_score = scores.values.map(&:to_i).min
        players.each do |player|
          score = scores[player].to_i
          stats[player][:lowest_score_rounds] += 1 if score == min_score
          stats[player][:lowest_score] = score if stats[player][:lowest_score].nil? || score < stats[player][:lowest_score]
          stats[player][:highest_score] = score if stats[player][:highest_score].nil? || score > stats[player][:highest_score]
        end
      end
      stats
    end
  end
end
