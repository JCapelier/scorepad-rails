class CreateRounds < ActiveRecord::Migration[7.1]
  def change
    create_table :rounds do |t|
      t.references :scoresheet, null: false, foreign_key: true
      t.jsonb :data

      t.timestamps
    end
  end
end
