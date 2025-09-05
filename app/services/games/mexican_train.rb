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
          "first_player" => first_player.display_name,
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
