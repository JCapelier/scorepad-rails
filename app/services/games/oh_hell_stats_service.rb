module Games
  class OhHellStatsService
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
        max_score = leaderboard.map { |entry| entry[:score] }.max
        winners = leaderboard.select { |entry| entry[:score] == max_score }.map { |entry| entry[:player] }
        winners.include?(@user.username)
      end
      win_count = won_games.size
      win_percent = total_games > 0 ? (win_count * 100 / total_games) : 0

      total_score = 0
      total_rounds = 0
      highest_score = 0
      longest_streak = 0
      most_accomplished = 0
      most_failed = 0
      trophy_counts = Hash.new(0)
      total_bids = 0
      total_tricks = 0
      total_bid_sum = 0
      total_tricks_sum = 0
      total_accomplished = 0

      sessions.each do |session|
        scoresheet = session.scoresheet
        next unless scoresheet
        rounds = scoresheet.rounds.order(:round_number)
        streak = 0; max_streak = 0; accomplished = 0; failed = 0
        rounds.each do |round|
          bid = round.data["bids"]&.[](@user.username)
          tricks = round.data["tricks"]&.[](@user.username)
          bid_i = Integer(bid) rescue nil
          tricks_i = Integer(tricks) rescue nil
          score = tricks_i if tricks_i
          total_score += score if tricks_i
          if !bid_i.nil? && !tricks_i.nil?
            total_bids += 1
            total_bid_sum += bid_i
            total_tricks += 1
            total_tricks_sum += tricks_i
            total_rounds += 1
            if tricks_i == bid_i
              streak += 1
              max_streak = [max_streak, streak].max
              accomplished += 1
              total_accomplished += 1
            else
              streak = 0
              failed += 1
            end
          end
        end
        longest_streak = [longest_streak, max_streak].max
        most_accomplished = [most_accomplished, accomplished].max
        most_failed = [most_failed, failed].max
        trophies = session.game.game_engine.trophies(scoresheet)
        trophies.each do |key, value|
          if value && value[:players].is_a?(Array) && value[:players].include?(@user.username)
            trophy_counts[key] += 1
          end
        end
      end

      avg_score_game = total_games > 0 ? (total_score.to_f / total_games).round(2) : 0
      avg_score_round = total_rounds > 0 ? (total_score.to_f / total_rounds).round(2) : 0
      avg_bid = total_bids > 0 ? (total_bid_sum.to_f / total_bids).round(2) : 0
      avg_tricks = total_tricks > 0 ? (total_tricks_sum.to_f / total_tricks).round(2) : 0
      success_rate = total_bids > 0 ? ((total_accomplished * 100.0) / total_bids).round(2) : 0

      {
        total_games: total_games,
        win_count: win_count,
        win_percent: win_percent,
        total_score: total_score,
        avg_score_game: avg_score_game,
        avg_score_round: avg_score_round,
        highest_score: highest_score,
        longest_streak: longest_streak,
        most_accomplished: most_accomplished,
        most_failed: most_failed,
        trophy_counts: trophy_counts,
        rounds_played: total_rounds,
        bids_accomplished: total_accomplished,
        success_rate: success_rate,
        avg_bid: avg_bid,
        avg_tricks: avg_tricks
      }
    end
  end
end
