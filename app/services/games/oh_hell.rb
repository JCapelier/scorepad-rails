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
          "first_player" => first_player.user.username,
          "dealer" => dealer.user.username,
          "phase" => "bidding"
        }
      end
    end

    def self.handle_bidding_phase(round, params)
      bids = params[:bids]
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

  end
end
