module Games
  class OhHell

    def self.initial_data(players, custom_rules = {})
      config = YAML.load_file(Rails.root.join('config/games/five_crowns.yml'))

      number_of_players = players.size
      max_cards = (52 / number_of_players.floor)
      config["max_cards"] = max_cards
      if custom_rules["long_game"] && custom_rules["long_game"]["value"] == "true"
        config["number_of_rounds"] = (max_cards * 2) - 1
        config["long_game"] = true
      else
        config["number_of_rounds"] = max_cards
      end

      {
        "config" => config,
        "number_of_rounds" => config["number_of_rounds"],
        "players" => players,
        "total_scores" => players.to_h { |player| [player, 0] },
        "long_game" => config["long_game"]
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
      ordered_players = players.sort_by { |player| player.position }
      number_of_players = ordered_players.size
      max_cards = config["max_cards"]

      (1..config["number_of_rounds"]).map do |round_number|
        first_player_index = (round_number - 1) % number_of_players
        dealer_index = (first_player_index - 1) % number_of_players

        first_player = ordered_players[first_player_index]
        dealer = ordered_players[dealer_index]

        cards_per_round = if config["long_game"]
          round_number <= max_cards ? round_number : (max_cards * 2) - round_number
        else
          round_number
        end
        {
          "cards_per_round" => cards_per_round,
          "first_player" => first_player.display_name,
          "dealer" => dealer.display_name,
          "phase" => "bidding"
        }
      end
    end

    def self.handle_bidding_phase(round, params)
      bids = params[:bid]
      move_data = []

      if bids.values.map(&:to_i).sum == round.data["cards_per_round"]
        return { error: "There has to be a loser..." }
      end
      bids.each do |username, bid|
        session_player = round.scoresheet.game_session.session_players.find_by(user: User.find_by(username: username))
        move_data << { round: round, session_player: session_player, move_type: "bid", data: { "bid" => bid} }
      end
      {
        instruction: "create bidding move",
        round_data_updates: { "bids" => bids, "phase" => "scoring" },
        move_data_list: move_data
      }
    end

    def self.handle_round_completion(round, params)
      tricks = params[:tricks]

      if tricks.values.map(&:to_i).sum != round.data["cards_per_round"]
        return { error: "Someone lied..." }
      end

      move_data_list = []
      scores = {}
      tricks.each do |username, trick|
        user = User.find_by(username: username)
        session_player = round.scoresheet.game_session.session_players.find_by(user: user)
        bid = round.data["bids"][username]
        if trick == bid
          score = (trick.to_i * 5) + 5
        else
          score = -5 * (trick.to_i - bid.to_i).abs
        end
        scores[username.to_s] = score

        move_data_list << {
          round: round,
          session_player: session_player,
          move_type: "tricks",
          data: { "tricks" => trick }
        }
      end

      {
        instruction: "go_to_next_round",
        round_data_updates: { "tricks" => tricks, "scores" => scores },
        move_data_list: move_data_list
      }
    end

    def self.player_stats(scoresheet)
      rounds = scoresheet.rounds.order(:round_number)
      players = scoresheet.game_session.session_players.map(&:display_name)

      leaderboard = self.leaderboard(scoresheet)
      scores_by_player = leaderboard.to_h { |entry| [entry[:player], entry[:score]] }
      ranks_by_player = leaderboard.to_h { |entry| [entry[:player], entry[:rank]] }

      stats = {}
      players.each do |player|
        stats[player] = {
          total_score: scores_by_player[player],
          rank: ranks_by_player[player],
          bid_accuracy: bid_accuracy(rounds, player),
          shortfall_ratio: shortfall_ratio(rounds, player),
          overshot_ratio: overshot_ratio(rounds, player),
          highest_bid_fulfilled: highest_bid_fulfilled(rounds, player),
          max_bid_tricks_distance: max_bid_tricks_distance(rounds, player),
          longest_streak: longest_streak(rounds, player),
          luckiest_round: luckiest_round(rounds, player),
          unluckiest_round: unluckiest_round(rounds, player)
        }
      end
      stats
    end

    def self.leaderboard(scoresheet)
      total_scores = calculate_total_scores(scoresheet)
      sorted = total_scores.sort_by { |_, score| -score.to_i }
      leaderboard = []
      prev_score = nil
      prev_rank = 0
      count = 0
      sorted.each do |player, score|
        count += 1
        rank = score == prev_score ? prev_rank : count
        leaderboard << { player: player, score: score, rank: rank }
        prev_score = score
        prev_rank = rank
      end
      leaderboard
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

    def self.bid_accuracy(rounds, player)
      total = rounds.size
      successful = rounds.count { |r| r.data.dig('bids', player).to_i == r.data.dig('tricks', player).to_i }
      percent = total > 0 ? ((successful.to_f / total) * 100).round(1) : 0
      { percent: percent, count: successful, total: total }
    end

    def self.shortfall_ratio(rounds, player)
      total = rounds.size
      shortfall = rounds.count { |r| r.data.dig('tricks', player).to_i < r.data.dig('bids', player).to_i }
      percent = total > 0 ? ((shortfall.to_f / total) * 100).round(1) : 0
      { percent: percent, count: shortfall, total: total }
    end

    def self.overshot_ratio(rounds, player)
      total = rounds.size
      overshot = rounds.count { |r| r.data.dig('tricks', player).to_i > r.data.dig('bids', player).to_i }
      percent = total > 0 ? ((overshot.to_f / total) * 100).round(1) : 0
      { percent: percent, count: overshot, total: total }
    end

    def self.highest_bid_fulfilled(rounds, player)
      rounds.select { |r| r.data.dig('bids', player).to_i == r.data.dig('tricks', player).to_i }
            .map { |r| r.data.dig('bids', player).to_i }
            .max || 0
    end

    def self.max_bid_tricks_distance(rounds, player)
      rounds.map { |r| (r.data.dig('bids', player).to_i - r.data.dig('tricks', player).to_i).abs }.max || 0
    end

    def self.longest_streak(rounds, player)
      max_streak = 0
      streak = 0
      rounds.each do |r|
        if r.data.dig('bids', player).to_i == r.data.dig('tricks', player).to_i
          streak += 1
          max_streak = [max_streak, streak].max
        else
          streak = 0
        end
      end
      max_streak
    end

    def self.luckiest_round(rounds, player)
      best = rounds.max_by { |r| r.data.dig('scores', player).to_i }
      best&.round_number
    end

    def self.unluckiest_round(rounds, player)
      worst = rounds.min_by { |r| r.data.dig('scores', player).to_i }
      worst&.round_number
    end
  end
end
