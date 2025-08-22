class AddGuestIdAndGuestNameToSessionPlayers < ActiveRecord::Migration[7.1]
  def change
    add_column :session_players, :guest_id, :string
    add_column :session_players, :guest_name, :string
  end
end
