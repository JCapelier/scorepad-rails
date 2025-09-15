module Games
  module Stats
    class OhHellUserStatsService < Users::UserStatsService
      def initialize(user)
        super
        @game = Game.find_by(title: 'Oh Hell')
      end

      def stats_hash_for(game)
        if sessions_completed_for(@game).length != 0
          super(@game).merge(
            total_bids: total_bids,
            total_tricks: total_tricks,
            average_bids_per_session: average_bids_per_session,
            average_tricks_per_session: average_tricks_per_session,
            bids_fulfilled: bids_tricks_stats[:successes],
            bids_overshot: bids_tricks_stats[:overshot],
            bids_shortfall: bids_tricks_stats[:shortfall],
            bids_success_ration: bids_tricks_stats[:success_ratio],
            bids_overshot_ratio: bids_tricks_stats[:overshot_ratio],
            bids_shortfall_ratio: bids_tricks_stats[:shortfall_ratio],
            longest_streak: longest_streak,
            highest_bid_fulfilled: highest_bid_fulfilled
          )
        end
      end

      def user_bid_moves
        rounds_for(@game)
          .flat_map(&:moves)
          .select { |move| move.move_type == 'bid' && move.session_player.user == @user }
      end

      def total_bids
        user_bid_moves.map { |bid_move| bid_move.data['bid'].to_i }.sum
      end

      def user_tricks_moves
        rounds_for(@game)
          .flat_map(&:moves)
          .select { |move| move.move_type == 'tricks' && move.session_player.user == @user }
      end

      def total_tricks
        user_tricks_moves.map { |tricks_move| tricks_move.data['tricks'].to_i }.sum
      end

      def bids_tricks_stats
        successes = 0
        overshots = 0
        shortfalls = 0

        rounds_for(@game).each do |round|
          puts "#{round.moves.find { |move| move.move_type == 'bid'}}"
          puts "#{round.moves.find { |move| move.session_player.user == @user }}"
          round_bid_move = round.moves.find { |move| move.move_type == "bid" && move.session_player.user == @user }
          bid = round_bid_move.data['bid'].to_i
          round_tricks_move = round.moves.find { |move| move.move_type == "tricks" && move.session_player.user == @user }
          tricks = round_tricks_move.data['tricks'].to_i
          if bid == tricks
            successes += 1
          elsif tricks > bid
            overshots += 1
          else
            shortfalls += 1
          end
        end

        success_ratio = ((successes.to_f / rounds_for(@game).length) * 100).round(2)
        overshot_ratio = ((overshots.to_f / rounds_for(@game).length) * 100).round(2)
        shortfall_ratio = ((shortfalls.to_f / rounds_for(@game).length) * 100).round(2)

        {
          successes: successes,
          overshots: overshots,
          shortfalls: shortfalls,
          success_ratio: success_ratio,
          overshot_ratio: overshot_ratio,
          shortfall_ratio: shortfall_ratio
        }
      end

      def average_bids_per_session
        total_bids / sessions_completed_for(@game).length
      end

      def average_tricks_per_session
        total_tricks / sessions_completed_for(@game).length
      end

      def highest_bid_fulfilled
        Games::Shared::SessionStatsService.highest_bid_fulfilled(rounds_for(@game), @user.username)
      end

      def longest_streak
        Games::Shared::SessionStatsService.longest_streak(rounds_for(@game), @user.username)
      end
    end
  end
end
