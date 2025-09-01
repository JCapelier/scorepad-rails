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

    def self.first_finisher_counts(scoresheet)
      # Needed for efficiency and safety trophies
      first_finisher_moves = scoresheet.rounds.map { |r| r.moves.find_by(move_type: 'first_finisher') }.compact
      counts = Hash.new(0)
      first_finisher_moves.each { |move| counts[move.session_player.display_name] += 1 }
      counts
    end

    def self.efficiency_trophy(scoresheet)
      counts = first_finisher_counts(scoresheet)
      max_count = counts.values.max || 0
      players = counts.select { |_, v| v == max_count }.keys
      { players: players, count: max_count }
    end

    def self.safety_trophy(scoresheet)
      counts = first_finisher_counts(scoresheet)
      min_count = counts.values.min || 0
      players = counts.select { |_, v| v == min_count }.keys
      { players: players, count: min_count }
    end

    def self.consistency_trophy(rounds)
      # Consistency Trophy: most rounds with lowest score
      lowest_counts = Hash.new(0)
      rounds.each do |r|
        scores = r.data['scores'] || {}
        min_score = scores.values.map(&:to_i).min
        scores.each do |player, score|
          lowest_counts[player] += 1 if score.to_i == min_score
        end
      end
      cons_max = lowest_counts.values.max || 0
      players = lowest_counts.select { |_, v| v == cons_max }.keys
      { players: players, count: cons_max }
    end

    def self.fail_trophy(rounds)
      # Fail Trophy (highest score in a single round)
      fail_scores = []
      rounds.each do |r|
        # Easier to find the highest with arrays
        r.data['scores']&.each { |player, score| fail_scores << [player, score.to_i] }
      end
      fail_max = fail_scores.map { |_, v| v }.max
      players = fail_scores.select { |_, v| v == fail_max }.map(&:first).uniq
      { players: players, count: fail_max}
    end

    def self.finish_status_trophies(scoresheet, status)
      # Common code for risk and reward and greed trophies
      rounds = scoresheet.rounds.order(:round_number)
      counts = Hash.new(0)
      rounds.each do |r|
        # move_for_finisher is a method of the Round model
        move = r.move_for_first_finisher
        # In the absence of finish_status, there's no risk or reward in finishing first.
        return nil unless move&.data && move.data['finish_status'].present?

        player = move.session_player.display_name
        counts[player] += 1 if move.data['finish_status'] == status
      end
      max = counts.values.max || 0
      players = counts.select { |_, v| v == max }.keys
      { players: players, count: max }
    end

    def self.risk_reward_trophy(scoresheet)
      finish_status_trophies(scoresheet, 'success')
    end

    def self.greed_trophy(scoresheet)
      finish_status_trophies(scoresheet, 'failure')
    end

    def self.trophies(scoresheet)
      rounds = scoresheet.rounds.order(:round_number)

      {
        efficiency: efficiency_trophy(scoresheet),
        consistency: consistency_trophy(rounds),
        safety: safety_trophy(scoresheet),
        fail: fail_trophy(rounds),
        risk_reward: risk_reward_trophy(scoresheet),
        greed: greed_trophy(scoresheet)
      }
    end
  end
end
