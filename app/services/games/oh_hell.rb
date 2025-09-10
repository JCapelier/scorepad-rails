module Games
  class OhHell < Games::Shared::GameBase

    def self.initial_data(players, custom_rules = {})
      data = super(players, custom_rules)
      config = data['config']

      number_of_players = players.size
      max_cards = (52 / number_of_players.floor)
      config["max_cards"] = max_cards
      if custom_rules["long_game"] && custom_rules["long_game"]["value"] == "true"
        config["number_of_rounds"] = (max_cards * 2) - 1
        config["long_game"] = true
      else
        config["number_of_rounds"] = max_cards
      end

      data.merge({
        "number_of_rounds" => config["number_of_rounds"],
        "total_scores" => players.to_h { |player| [player, 0] },
        "long_game" => config["long_game"]
      })
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

      leaderboard = self.leaderboard(scoresheet, ascending: false)
      scores_by_player = leaderboard.to_h { |entry| [entry[:player], entry[:score]] }
      ranks_by_player = leaderboard.to_h { |entry| [entry[:player], entry[:rank]] }

      stats = {}
      players.each do |player|
        stats[player] = {
          total_score: scores_by_player[player],
          rank: ranks_by_player[player],
          bid_accuracy: session_stats_service.bid_accuracy(rounds, player),
          shortfall_ratio: session_stats_service.shortfall_ratio(rounds, player),
          overshot_ratio: session_stats_service.overshot_ratio(rounds, player),
          highest_bid_fulfilled: session_stats_service.highest_bid_fulfilled(rounds, player),
          max_bid_tricks_distance: session_stats_service.max_bid_tricks_distance(rounds, player),
          longest_streak: session_stats_service.longest_streak(rounds, player),
          luckiest_round: session_stats_service.luckiest_round(rounds, player),
          unluckiest_round: session_stats_service.unluckiest_round(rounds, player)
        }
      end
      stats
    end
  end
end
