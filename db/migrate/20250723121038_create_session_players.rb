class CreateSessionPlayers < ActiveRecord::Migration[7.1]
  def change
    create_table :session_players do |t|
      t.references :user, null: false, foreign_key: true
      t.references :game_session, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end
  end
end
