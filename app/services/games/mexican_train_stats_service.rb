module Games
  class MexicanTrainStatsService
    def initialize(user, game)
      @user = user
      @game = game
    end

    def stats
      sessions = @user.session_players.includes(:game_session => [:game, :scoresheet, { scoresheet: :rounds }]).map(&:game_session).select { |gs| gs.game == @game && gs.status == 'completed' }
      total_games = sessions.size
      won_games = sessions.select do |s|
        leaderboard = @game.game_engine.leaderboard(s.scoresheet)
        next false unless leaderboard.present?
        min_score = leaderboard.map { |entry| entry[:score] }.min
        leaderboard.select { |entry| entry[:score] == min_score }.map { |entry| entry[:player] }.include?(@user.username)
      end
      win_count = won_games.size
      win_percent = total_games > 0 ? (win_count * 100 / total_games) : 0

      total_score = 0
      total_rounds = 0
      total_first_finisher = 0
      highest_score = 0
      longest_streak = 0
      trophy_counts = Hash.new(0)

      sessions.each do |session|
        scoresheet = session.scoresheet
        next unless scoresheet
        rounds = scoresheet.rounds.order(:round_number)
        streak = 0; max_streak = 0
        rounds.each do |round|
          score = round.data["scores"]&.[](@user.username).to_i
          total_score += score
          total_rounds += 1
          highest_score = [highest_score, score].max
          if score == 0
            streak += 1
            max_streak = [max_streak, streak].max
          else
            streak = 0
          end
        end
        longest_streak = [longest_streak, max_streak].max
        trophies = session.game.game_engine.trophies(scoresheet)
        trophies.each do |key, value|
          if value && value[:players].is_a?(Array) && value[:players].include?(@user.username)
            trophy_counts[key] += 1
          end
        end
      end

      avg_score_game = total_games > 0 ? (total_score.to_f / total_games).round(2) : 0
      avg_score_round = total_rounds > 0 ? (total_score.to_f / total_rounds).round(2) : 0

      {
        total_games: total_games,
        win_count: win_count,
        win_percent: win_percent,
        total_score: total_score,
        avg_score_game: avg_score_game,
        avg_score_round: avg_score_round,
        highest_score: highest_score,
        longest_streak: longest_streak,
        total_first_finisher: total_first_finisher,
        trophy_counts: trophy_counts
      }
    end
  end
end
