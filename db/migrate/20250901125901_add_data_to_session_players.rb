class AddDataToSessionPlayers < ActiveRecord::Migration[7.1]
  def change
    add_column :session_players, :data, :jsonb
  end
end
