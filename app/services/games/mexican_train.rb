module Games
  class MexicanTrain

    def self.initial_data(players, custom_rules = {})
      config = YAML.load_file(Rails.root.join('config/games/five_crowns.yml'))

      if custom_rules["long_game"] && custom_rules["long_game"]["value"] == "true"
        config["number_of_rounds"] = 25
        config["long_game"] = { "value" => true }
      end

      {
        "config" => config,
        "number_of_rounds" => config["number_of_rounds"],
        "players" => players,
        "total_scores" => players.to_h { |player| [player, 0] },
        "long_game" => config["long_game"]
      }
    end

    def self.starting_domino(round_number)
      domino = 12 - ((round_number - 1) % 13)
      if domino == 12
        starting_domino = "Double joker"
      else
        starting_domino = "Double #{domino}"
      end
    end

    def self.max_players
      config = YAML.load_file(Rails.root.join('config/games/mexican_train.yml'))
      config['max_players']
    end

    def self.min_players
      config = YAML.load_file(Rails.root.join('config/games/mexican_train.yml'))
      config['min_players']
    end

    def self.round_data(players, config)
      ordered_players = players.sort_by { |player| player.position }
      number_of_players = ordered_players.size

      (1..config["number_of_rounds"]).map do |round_number|
        first_player_index = (round_number - 1) % number_of_players
        dealer_index = (first_player_index - 1) % number_of_players

        first_player = ordered_players[first_player_index]
        dealer = ordered_players[dealer_index]
        starting_domino = starting_domino(round_number)

        {
          "starting_domino" => starting_domino(round_number),
          "first_player" => first_player.user.username,
          "starting_domino" => starting_domino
        }
      end
    end

    def self.handle_round_completion(round, params)
      scores = params[:scores]
      first_finisher = params[:first_finisher]
      first_score = scores[first_finisher].to_i if scores && first_finisher

      if first_score != 0
        return { error: "First finisher must have a score of 0" }
      end

      session_player = round.scoresheet.game_session.session_players.find_by(user: User.find_by(username: first_finisher))
      move_data = { round: round, session_player: session_player, move_type: "first_finisher", data: {} }

      {
        instruction: "go_to_next_round",
        round_data_updates: { "scores" => scores, "first_finisher" => first_finisher },
        move_data: move_data
      }
    end

    def self.calculate_total_scores(scoresheet)
      rounds = scoresheet.rounds.order(:round_number)
      totals = Hash.new(0)
      rounds.each do |round|
        scores = round.data["scores"] || {}
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
        r.data["scores"]&.each do |player, score|
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

    # Trophy/stat calculations for results view
    def self.trophies(scoresheet)
      rounds = scoresheet.rounds.order(:round_number)
      players = scoresheet.game_session.session_players.map { |sp| sp.user.username }
      rules = scoresheet.data.select { |_, v| v.is_a?(Hash) && v.key?("value") }

      # Efficiency Trophy (ex aequo)
      first_finish_counts = Hash.new(0)
      rounds.each { |r| first_finish_counts[r.data["first_finisher"]] += 1 if r.data["first_finisher"].present? }
      eff_max = first_finish_counts.values.max || 0
      eff_players = first_finish_counts.select { |_, v| v == eff_max }.keys

      # Consistency Trophy (ex aequo)
      zero_counts = Hash.new(0)
      rounds.each do |r|
        r.data["scores"]&.each { |player, score| zero_counts[player] += 1 if score.to_i == 0 }
      end
      cons_max = zero_counts.values.max || 0
      cons_players = zero_counts.select { |_, v| v == cons_max }.keys
      show_consistency = cons_max > 0

      # Winning Streak Trophy (ex aequo)
      streaks = Hash.new(0)
      players.each do |player|
        max_streak = 0; current = 0
        rounds.each do |r|
          score = r.data["scores"]&.[](player)
          if score.to_i == 0
            current += 1; max_streak = [max_streak, current].max
          else
            current = 0
          end
        end
        streaks[player] = max_streak
      end
      streak_max = streaks.values.max || 0
      streak_players = streaks.select { |_, v| v == streak_max }.keys
      show_streak = streak_max > 0

      # Fail Trophy (ex aequo)
      fail_scores = []
      rounds.each do |r|
        r.data["scores"]&.each { |player, score| fail_scores << [player, score.to_i] }
      end
      fail_max = fail_scores.map { |_, v| v }.max || 0
      fail_players = fail_scores.select { |_, v| v == fail_max }.map(&:first).uniq

      # Martyr Trophy (ex aequo)
      martyr_counts = Hash.new(0)
      rounds.each do |r|
        r.data["scores"]&.each do |player, score|
          unless r.data["first_finisher"] == player || score.to_i == 0
            martyr_counts[player] += 1
          end
        end
      end
      martyr_max = martyr_counts.values.max || 0
      martyr_players = martyr_counts.select { |_, v| v == martyr_max }.keys

      {
        efficiency: { players: eff_players, count: eff_max },
        consistency: show_consistency ? { players: cons_players, count: cons_max } : nil,
        winning_streak: show_streak ? { players: streak_players, count: streak_max } : nil,
        fail: { players: fail_players, count: fail_max },
        martyr: { players: martyr_players, count: martyr_max },
      }
    end
  end
end
