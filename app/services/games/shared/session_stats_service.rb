module Games
  module Shared
    class SessionStatsService
      def self.average_score_per_round(rounds, players)
        total_rounds = rounds.last&.round_number
        scoresheet = rounds.first&.scoresheet
        leaderboard = scoresheet ? scoresheet.game.game_engine.leaderboard(scoresheet, scoresheet.game.game_engine.ascending_scoring?) : []
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
          total = stats[player][:finish_success] + stats[player][:finish_failure]
          stats[player][:finish_ratio] = total > 0 ? ((stats[player][:finish_success].to_f / total) * 100).round(2) : nil
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

      # These should be made more robust by using Move instead of digging round data (that's why they exist...).
      # But, it would d make the method more complex.
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
    end
  end
end
