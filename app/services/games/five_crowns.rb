module Games
  class FiveCrowns

    def self.initial_data(players, custom_rules = {})
      config = YAML.load_file(Rails.root.join('config/games/five_crowns.yml'))

      if custom_rules["long_game"] == "true"
        config["number_of_rounds"] = 21
      end

      if custom_rules["early_finish"]
        config["early_finish"] = true
      end

      {
        "config" => config,
        "players" => players,
        "total_scores" => players.to_h { |player| [player, 0] },
        "early_finish" => config["early_finish"]
      }
    end

    def self.cards_for_round(round_number)
      round_number + 2
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

      (1..config["number_of_rounds"]).map do |round_number|
        first_player_index = (round_number - 1) % number_of_players
        dealer_index = (first_player_index - 1) % number_of_players

        first_player = ordered_players[first_player_index]
        dealer = ordered_players[dealer_index]

        {
          "cards_per_round" => config["cards_per_round"][round_number],
          "wild_cards" => config["wild_cards"][round_number],
          "first_player" => first_player.user.username,
          "dealer" => dealer.user.username
        }
      end
    end

    def self.handle_round_completion(round, params)
      scores = params[:scores]
      first_finisher = params[:first_finisher]
      early_finish = round.scoresheet.data["early_finish"] == "true"
      first_score = scores[first_finisher].to_i if scores && first_finisher

      if !early_finish && first_score != 0
        return { error: "First finisher must have score 0 unless early finish is enabled." }
      end

      session_player = round.scoresheet.game_session.session_players.find_by(user: User.find_by(username: first_finisher))
      {
        round_data_updates: { "scores" => scores, "first_finisher" => first_finisher },
        move_data: { round: round, session_player: session_player, move_type: "first_finisher" }
      }
    end

    def self.calculate_total_scores(rounds)
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
