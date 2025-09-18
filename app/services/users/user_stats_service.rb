module Users
  class UserStatsService
    def initialize(user)
      @user = user
    end

    def stats_hash_for(game)
      if sessions_completed_for(game).length != 0
        hash = {
          sessions_completed: sessions_completed_for(game).length,
          sessions_won: sessions_won_for(game).length,
          sessions_win_ratio: sessions_win_ratio_for(game),
          total_score: total_score_for(game),
          highest_session_score: highest_session_score_for(game),
          lowest_session_score: lowest_session_score_for(game),
          average_score_per_session: average_score_per_session_for(game),
          highest_round_score: highest_round_score_for(game),
          lowest_round_score: lowest_round_score_for(game),
          average_score_per_round: average_score_per_round_for(game)
        }
        if game.game_engine.include_first_finisher?
          hash.merge(
          first_finisher_total: first_finisher_total_for(game),
          first_finisher_successes: first_finisher_success_count_for(game),
          first_finisher_failures: first_finisher_failure_count_for(game),
          first_finisher_succes_ratio: first_finisher_failure_count_for(game)
          )
        end
      end
      hash
    end

    def rounds_for(game)
      sessions_completed_for(game)
        .map { |session| session.scoresheet.rounds }
        .flatten
    end

    def first_finisher_moves_for(game)
      rounds_for(game).select { |round| round.move_for_first_finisher && round.move_for_first_finisher.data['player'] == @user.username }
    end

    def ordered_games_played
      user_sessions = @user.session_players.includes(game_session: :game)
      games_played = user_sessions.group_by { |sp| sp.game_session.game }
      games_played.keys.sort_by { |game| -games_played[game].map { |sp| sp.updated_at }.max.to_i }
    end

    def sessions_completed
      @user.game_sessions.select { |session| session.status == 'completed' }
    end

    def sessions_won
      sessions_completed.select do |session|
        winners = session.scoresheet.data['winner_username']
        Array(winners).include?(@user.username)
      end
    end

    def sessions_win_ratio
      ((sessions_won.length.to_f / sessions_completed.length) * 100).round(2)
    end

    def sessions_completed_for(game)
      sessions_completed.select { |session| session.game == game }
    end

    def sessions_won_for(game)
      sessions_completed_for(game).select do |session|
        winners = session.scoresheet.data['winner_username']
        Array(winners).include?(@user.username)
      end
    end

    def sessions_win_ratio_for(game)
      ((sessions_won_for(game).length / sessions_completed_for(game).length) * 100).round(2)
    end

    def total_score_for(game)
      player_total_score_per_session = sessions_completed_for(game).map { |session| game.game_engine.calculate_total_scores(session.scoresheet)[@user.username.to_s].to_i }
      player_total_score_per_session.sum
    end

    def average_score_per_session_for(game)
      player_total_score_per_session = sessions_completed_for(game).map { |session| game.game_engine.calculate_total_scores(session.scoresheet)[@user.username.to_s].to_i }
      (player_total_score_per_session.sum.to_f / player_total_score_per_session.length).round(2) if player_total_score_per_session.any?
    end

    def average_score_per_round_for(game)
      player_score_per_round = rounds_for(game).map { |round| round.data['scores'][@user.username.to_s].to_i }
      (player_score_per_round.sum / player_score_per_round.length).round(2)
    end

    def highest_session_score_for(game)
      sessions_completed_for(game).map { |session| game.game_engine.calculate_total_scores(session.scoresheet)[@user.username] }.max
    end

    def lowest_session_score_for(game)
      sessions_completed_for(game).map { |session| game.game_engine.calculate_total_scores(session.scoresheet)[@user.username] }.min
    end

    def highest_round_score_for(game)
      rounds_for(game).map { |round| round.data['scores'][@user.username.to_s].to_i }.max
    end

    def lowest_round_score_for(game)
      rounds_for(game).map { |round| round.data['scores'][@user.username.to_s].to_i }.min
    end

    def first_finisher_total_for(game)
      first_finisher_moves_for(game).length
    end

    def first_finisher_success_count_for(game)
      first_finisher_moves_for(game).select { |move| move.data['finish_status'] && move.data['finish_status'] == 'success' }.length
    end

    def first_finisher_failure_count_for(game)
      first_finisher_moves_for(game).select { |move| move.data['finish_status'] && move.data['finish_status'] == 'failure' }.length
    end

    def first_finisher_succes_ratio_for(game)
      ((first_finisher_success_count_for(game).to_f / first_finisher_total_for(game)) * 100).round(2)
    end
  end
end
