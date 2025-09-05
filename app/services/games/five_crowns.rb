module Games
  class FiveCrowns

    def self.initial_data(players, custom_rules = {})
      config = YAML.load_file(Rails.root.join('config/games/five_crowns.yml'))

      if custom_rules['long_game'] && custom_rules['long_game']['value'] == 'true'
        config['number_of_rounds'] = 21
        config['long_game'] = { 'value' => true }
      end

      config['early_finish']['value'] = true if custom_rules.dig('early_finish', 'value') == 'true'

      if custom_rules.dig('early_finish', 'subrules', 'double_if_not_lowest') == 'true'
        config['early_finish']['subrules']['double_if_not_lowest'] = true
      end

      {
        'config' => config,
        'number_of_rounds' => config['number_of_rounds'],
        'players' => players,
        'total_scores' => players.to_h { |player| [player, 0] },
        'early_finish' => config['early_finish'],
        'long_game' => config['long_game']
      }
    end

    def self.max_players
      config = YAML.load_file(Rails.root.join('config/games/five_crowns.yml'))
      config['max_players']
    end

    def self.min_players
      config = YAML.load_file(Rails.root.join('config/games/five_crowns.yml'))
      config['min_players']
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

    # Returns sorted leaderboard as array of [player, score] pairs
    def self.leaderboard(scoresheet)
      rounds = scoresheet.rounds.order(:round_number)
      total_scores = Hash.new(0)
      rounds.each do |r|
        r.data['scores']&.each do |player, score|
          total_scores[player] += score.to_i
        end
      end
      # Sort by score ascending (lowest is best)
      sorted = total_scores.sort_by { |_, score| score.to_i }
      leaderboard = []
      last_score = nil
      last_rank = 0
      sorted.each_with_index do |(player, score), i|
        if score == last_score
          rank = last_rank
        else
          rank = i + 1
          last_rank = rank
          last_score = score
        end
        leaderboard << { player: player, score: score, rank: rank }
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
#     # Trophy/stat calculations for results view
#     def self.trophies(scoresheet)
#       rounds = scoresheet.rounds.order(:round_number)
#       players = scoresheet.game_session.session_players.map { |sp| sp.display_name }
#       rules = scoresheet.data.select { |_, v| v.is_a?(Hash) && v.key?('value') }
#       early_finish = rules['early_finish']&.[]('value') == true
#       double_if_not_lowest = rules['early_finish']&.dig('subrules', 'double_if_not_lowest') == true

#       # Efficiency Trophy (ex aequo)
#       first_finish_counts = Hash.new(0)
#       rounds.each { |r| first_finish_counts[r.data['first_finisher']] += 1 if r.data['first_finisher'].present? }
#       eff_max = first_finish_counts.values.max || 0
#       eff_players = first_finish_counts.select { |_, v| v == eff_max }.keys

#       # Consistency Trophy (ex aequo)
#       zero_counts = Hash.new(0)
#       rounds.each do |r|
#         r.data['scores']&.each { |player, score| zero_counts[player] += 1 if score.to_i == 0 }
#       end
#       cons_max = zero_counts.values.max || 0
#       cons_players = zero_counts.select { |_, v| v == cons_max }.keys
#       show_consistency = cons_max > 0

#       # Winning Streak Trophy (ex aequo)
#       streaks = Hash.new(0)
#       players.each do |player|
#         max_streak = 0; current = 0
#         rounds.each do |r|
#           score = r.data['scores']&.[](player)
#           if score.to_i == 0
#             current += 1; max_streak = [max_streak, current].max
#           else
#             current = 0
#           end
#         end
#         streaks[player] = max_streak
#       end
#       streak_max = streaks.values.max || 0
#       streak_players = streaks.select { |_, v| v == streak_max }.keys
#       show_streak = streak_max > 0

#       # Fail Trophy (ex aequo)
#       fail_scores = []
#       rounds.each do |r|
#         r.data['scores']&.each { |player, score| fail_scores << [player, score.to_i] }
#       end
#       fail_max = fail_scores.map { |_, v| v }.max || 0
#       fail_players = fail_scores.select { |_, v| v == fail_max }.map(&:first).uniq

#       # Martyr Trophy (ex aequo)
#       martyr_counts = Hash.new(0)
#       rounds.each do |r|
#         r.data['scores']&.each do |player, score|
#           unless r.data['first_finisher'] == player || score.to_i == 0
#             martyr_counts[player] += 1
#           end
#         end
#       end
#       martyr_max = martyr_counts.values.max || 0
#       martyr_players = martyr_counts.select { |_, v| v == martyr_max }.keys

#       # Risk & Reward and Greed Trophies (ex aequo)
#       risk_counts = Hash.new(0); greed_counts = Hash.new(0)
#       show_risk, show_greed = false, false
#       if early_finish && double_if_not_lowest
#         rounds.each do |r|
#           move = r.move_for_first_finisher rescue nil
#           next unless move && move.data && move.data['finish_status'].present?
#           player = move.session_player.display_name rescue nil
#           result = move.data['finish_status']
#           score = r.data['scores']&.[](player).to_i
#           if result == 'success' && score > 0
#             risk_counts[player] += 1
#           elsif result == 'failure' && score > 0
#             greed_counts[player] += 1
#           end
#         end
#         risk_max = risk_counts.values.max || 0
#         risk_players = risk_counts.select { |_, v| v == risk_max }.keys
#         show_risk = risk_max > 0
#         greed_max = greed_counts.values.max || 0
#         greed_players = greed_counts.select { |_, v| v == greed_max }.keys
#         show_greed = greed_max > 0
#       else
#         risk_players, risk_max, greed_players, greed_max = [], 0, [], 0
#       end

#       {
#         efficiency: { players: eff_players, count: eff_max },
#         consistency: show_consistency ? { players: cons_players, count: cons_max } : nil,
#         winning_streak: show_streak ? { players: streak_players, count: streak_max } : nil,
#         fail: { players: fail_players, count: fail_max },
#         martyr: { players: martyr_players, count: martyr_max },
#         risk_reward: show_risk ? { players: risk_players, count: risk_max } : nil,
#         greed: show_greed ? { players: greed_players, count: greed_max } : nil
#       }
#     end
#   end

# end
