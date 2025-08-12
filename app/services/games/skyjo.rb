module Games
  class Skyjo

    def self.initial_data(players, custom_rules = {})
      config = YAML.load_file(Rails.root.join('config/games/skyjo.yml'))

      if custom_rules["child_mode"] && custom_rules["child_mode"]["value"] == "true"
        config["child_mode"] = true
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
        "dealer" => dealer.user.username
      }]
    end

    def self.handle_round_completion(round, params)
      scores = params[:scores]
      first_finisher = params[:first_finisher]
      child_mode_enabled = round.scoresheet.data["child_mode"] == true

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
      current_dealer = round.data["dealer"]
      ordered_players = players.sort_by { |player| player.position }
      usernames = ordered_players.map { |p| p.user.username }
      dealer_index = usernames.index(current_dealer)
      next_dealer = usernames[(dealer_index + 1) % usernames.size]

      {
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

    def self.leaderboard(scoresheet)
      rounds = scoresheet.rounds.order(:round_number)
      total_scores = Hash.new(0)
      rounds.each do |r|
        r.data["scores"]&.each do |player, score|
          total_scores[player] += score.to_i
        end
      end
      # Sort by score ascending (lower is better in Skyjo)
      sorted = total_scores.sort_by { |_, score| score.to_i }
      leaderboard = []
      prev_score = nil
      prev_rank = 0
      count = 0
      sorted.each do |player, score|
        count += 1
        if score == prev_score
          rank = prev_rank
        else
          rank = count
        end
        leaderboard << { player: player, score: score, rank: rank }
        prev_score = score
        prev_rank = rank
      end
      leaderboard
    end

    def self.trophies(scoresheet)
      rounds = scoresheet.rounds.order(:round_number)
      players = scoresheet.game_session.session_players.map { |sp| sp.user.username }
      rules = scoresheet.data.select { |_, v| v.is_a?(Hash) && v.key?("value") }
      child_mode = rules["child_mode"] == true
      custom_score_limit = rules["custom_score_limit"] == true

      # Efficiency Trophy
      first_finish_counts = Hash.new(0)
      rounds.each { |r| first_finish_counts[r.data["first_finisher"]] += 1 if r.data["first_finisher"].present? }
      eff_count = first_finish_counts.values.max || 0
      eff_players = first_finish_counts.select { |_, v| v == eff_count }.keys

      # Consistency Trophy: most rounds with lowest score (ex aequo)
      lowest_counts = Hash.new(0)
      rounds.each do |r|
        scores = r.data["scores"] || {}
        next if scores.empty?
        min_score = scores.values.map(&:to_i).min
        scores.each do |player, score|
          lowest_counts[player] += 1 if score.to_i == min_score
        end
      end
      cons_max = lowest_counts.values.max || 0
      cons_players = lowest_counts.select { |_, v| v == cons_max }.keys
      show_consistency = cons_max > 0

      # Fail Trophy (ex aequo)
      fail_scores = []
      rounds.each do |r|
        r.data["scores"]&.each { |player, score| fail_scores << [player, score.to_i] }
      end
      fail_max = fail_scores.map { |_, v| v }.max || 0
      fail_players = fail_scores.select { |_, v| v == fail_max }.map(&:first).uniq

      # Safety Trophy: least first_finisher
      first_finish_counts = Hash.new(0)
      rounds.each { |r| first_finish_counts[r.data["first_finisher"]] += 1 if r.data["first_finisher"].present? }
      min_count = first_finish_counts.values.min || 0
      safe_players = first_finish_counts.select { |_, v| v == min_count }.keys
      show_safety = min_count > 0 && safe_players.any?

      # Risk & Reward and Greed Trophies (use move.data['finish_status'])
      risk_counts = Hash.new(0); greed_counts = Hash.new(0)
      show_risk, show_greed = false, false
      rounds.each do |r|
        move = r.move_for_first_finisher rescue nil
        next unless move && move.data && move.data["finish_status"].present?
        player = move.session_player.user.username rescue nil
        score = r.data["scores"]&.[](player).to_i
        if move.data["finish_status"] == "success" && score > 0
          risk_counts[player] += 1
        elsif move.data["finish_status"] == "failure" && score > 0
          greed_counts[player] += 1
        end
      end
      risk_max = risk_counts.values.max || 0
      risk_players = risk_counts.select { |_, v| v == risk_max }.keys
      show_risk = risk_max > 0
      greed_max = greed_counts.values.max || 0
      greed_players = greed_counts.select { |_, v| v == greed_max }.keys
      show_greed = greed_max > 0

      {
        efficiency: { players: eff_players, count: eff_count },
        consistency: show_consistency ? { players: cons_players, count: cons_max } : nil,
        safety: { players: safe_players, count: min_count },
        fail: { players: fail_players, count: fail_max },
        risk_reward: show_risk ? { players: risk_players, count: risk_max } : nil,
        greed: show_greed ? { players: greed_players, count: greed_max } : nil
      }
    end
  end
end
