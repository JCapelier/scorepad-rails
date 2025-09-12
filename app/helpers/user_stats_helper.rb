module UserStatsHelper
  def user_stats_service_for(game, user)
    case game.title
    when 'Oh Hell'
      Games::Stats::OhHellUserStatsService.new(user)
    else
      Users::UserStatsService.new(user)
    end
  end

  def stats_titles
    {
    sessions_completed: "Games completed",
    sessions_won: "Games won",
    sessions_win_ratio: "Win ratio",
    total_score: "Total score",
    highest_session_score: "Highest score in a game",
    lowest_session_score: "Lowest score in a session",
    average_score_per_session: "Average score per game",
    average_score_per_session_for: "Average score per game",
    highest_round_score: "Highest score in a round",
    lowest_round_score: "Lowest score in a round",
    average_score_per_round: "Average score per round",
    # Games with first finisher
    first_finisher_total: "Total of rounds finished first",
    first_finisher_successes: "First finisher successes",
    first_finisher_failures: "First finisher failures",
    first_finisher_succes_ratio: "First finisher success ratio",
    # Oh Hell specific
    total_bids: "Total bids",
    total_tricks: "Total tricks",
    average_bids_per_session: "Average bids per session",
    average_tricks_per_session: "Average tricks per session",
    bids_fulfilled: "Bids fulfilled",
    bids_overshot: "Bids overshot",
    bids_shortfall: "Bids shortfall",
    bids_success_ration: "Bids success ratio",
    bids_overshot_ratio: "Bids overshot ratio",
    bids_shortfall_ratio: "Bids shortfall ratio",
    longest_streak: "Longest fulfilled bids streak",
    highest_bid_fulfilled: "Highest bid fulfilled"
    }
  end
end
