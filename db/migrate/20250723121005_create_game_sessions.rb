class CreateGameSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :game_sessions do |t|
      t.references :game, null: false, foreign_key: true
      t.datetime :starts_at
      t.datetime :ends_at
      t.string :place
      t.string :notes

      t.timestamps
    end
  end
end
