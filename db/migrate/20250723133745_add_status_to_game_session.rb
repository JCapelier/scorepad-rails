class AddStatusToGameSession < ActiveRecord::Migration[7.1]
  def change
    add_column :game_sessions, :status, :string
  end
end
