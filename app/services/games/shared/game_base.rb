module Games
  module Shared
    class GameBase
      def self.session_stats_service
        Games::Shared::SessionStatsService
      end

      def self.config_file
        game_name = self.name.demodulize.underscore
        Rails.root.join("config/games/#{game_name}.yml")
      end

      def self.load_config
        YAML.load_file(self.config_file)
      end

      def self.min_players
        config = self.load_config
        config['min_players']
      end

      def self.max_players
        config = self.load_config
        config['max_players']
      end

      def self.initial_data(players, custom_rules = {})
        config = self.load_config

        {
          'config' => config,
          'players' => players,
          'total_scores' => players.to_h { |player| [player, 0] }
        }
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

      def self.leaderboard(scoresheet, ascending: true)
        total_scores = calculate_total_scores(scoresheet)
        sorted = ascending ? total_scores.sort_by { |_, score| score.to_i } : total_scores.sort_by { |_, score| -score.to_i }
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
    end
  end
end
