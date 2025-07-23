class CreateMoves < ActiveRecord::Migration[7.1]
  def change
    create_table :moves do |t|
      t.references :session_player, null: false, foreign_key: true
      t.references :round, null: false, foreign_key: true
      t.string :move_type
      t.jsonb :data

      t.timestamps
    end
  end
end
