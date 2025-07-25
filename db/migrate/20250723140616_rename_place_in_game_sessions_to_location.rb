class RenamePlaceInGameSessionsToLocation < ActiveRecord::Migration[7.1]
  def change
    rename_column :game_sessions, :place, :location
  end
end
