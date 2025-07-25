module Games
  class FiveCrowns
    def self.initial_data(players)
      {
        "game_type" => "five_crowns",
        "players" => players,
        "current_round" => 1,
        "max_rounds" => 11,
        "total_scores" => players.to_h { |player| [player, 0] },
        "round_details" => (1..11).map { |round|
          { "round" => round, "cards" => round + 2 }
        }
      }
    end

    def self.cards_for_round(round_number)
      round_number + 2
    end

    def self.wild_cards(round_number)
      if round_number <= 8
        "#{round_number + 2}"
      else
        case round_number
        when 9
          "Jack"
        when 10
          "Queen"
        when 11
          "King"
        end
      end
    end

    def self.max_players
      7
    end

    def self.min_players
      2
    end
  end
end
