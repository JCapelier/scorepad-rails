class MakeUserIdNullableInSessionPlayers < ActiveRecord::Migration[7.1]
  def change
    change_column_null :session_players, :user_id, true
  end
end
