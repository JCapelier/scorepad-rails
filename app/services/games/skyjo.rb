module Games
  class Skyjo

    def self.initial_data(players, custom_rules = {})
      config = YAML.load_file(Rails.root.join('config/games/skyjo.yml'))

      if custom_rules["child_mode"] && custom_rules["child_mode"]["value"] == "true"
        config["child_mode"] = { "value" => true }
      end

      if custom_rules["custom_score_limit"] && custom_rules["custom_score_limit"]["value"].present?
        config["custom_score_limit"] = true
        config["score_limit"] = custom_rules["custom_score_limit"]["value"].to_i
      end

      {
        "config" => config,
        "score_limit" => config["score_limit"],
        "players" => players,
        "total_scores" => players.to_h { |player| [player, 0] },
        "child_mode" => config["child_mode"],
        "custom_score_limit" => config["custom_score_limit"]
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
      ordered_players = players.sort_by { |player| player.position }
      first_player = ordered_players.first
      dealer = ordered_players.last


      [{
        "first_player" => first_player.user.username,
        "dealer" => dealer.user.username
      }]
    end

    def self.handle_round_completion(round, params)
      scores = params[:scores]
      first_finisher = params[:first_finisher]
      child_mode_enabled = round.scoresheet.data["child_mode"]["value"] == true

      first_score = scores[first_finisher].to_i if scores && first_finisher

      unless child_mode_enabled
        first_score = scores[first_finisher].to_i
        other_scores = scores.reject { |player, _| player == first_finisher }.values.map(&:to_i)
        if other_scores.all? { |score| first_score < score }
          finish = "success"
        else
          scores[first_finisher] = first_score * 2
          finish = "failure"
        end
      end

      session_player = round.scoresheet.game_session.session_players.find_by(user: User.find_by(username: first_finisher))
      move_data = { round: round, session_player: session_player, move_type: "first_finisher", data: { finish_status: finish } }
      totals = calculate_total_scores(round.scoresheet)

      projected_totals = projected_totals(round.scoresheet, round, scores)
      score_limit = round.scoresheet.data["score_limit"]

      if projected_totals.values.any? {|projected_total| projected_total >= score_limit}
        instruction = "end_game"
      else
        instruction = "create_next_round"
      end
      {
        instruction: instruction,
        round_data_updates: { "scores" => scores, "first_finisher" => first_finisher },
        move_data: move_data,
        next_round_data: next_round_data(round)
      }
    end

    def self.next_round_data(round)
      players = round.scoresheet.game_session.session_players.order(:position)
      current_first_player = round.data["first_player"]
      current_dealer = round.data["dealer"]
      ordered_players = players.sort_by { |player| player.position }
      usernames = ordered_players.map { |p| p.user.username }

      first_index = usernames.index(current_first_player)
      dealer_index = usernames.index(current_dealer)

      next_first_player = usernames[(first_index + 1) % usernames.size]
      next_dealer = usernames[(dealer_index + 1) % usernames.size]

      {
        "first_player" => next_first_player,
        "dealer" => next_dealer
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

    def self.projected_totals(scoresheet, current_round, incoming_scores)
      totals = calculate_total_scores(scoresheet)

      old_scores = (current_round.data || {})["scores"] || {}
      old_scores.each { |player, score| totals[player] -= score.to_i }

      (incoming_scores || {}).each { |player, score| totals[player] += score.to_i }

      totals
    end
  end
end
