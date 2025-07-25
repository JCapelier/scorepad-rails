class AddNumberOfPlayersToGameSessions < ActiveRecord::Migration[7.1]
  def change
    add_column :game_sessions, :number_of_players, :integer
  end
end
