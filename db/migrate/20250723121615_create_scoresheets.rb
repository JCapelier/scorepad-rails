class CreateScoresheets < ActiveRecord::Migration[7.1]
  def change
    create_table :scoresheets do |t|
      t.jsonb :data
      t.references :game_session, null: false, foreign_key: true

      t.timestamps
    end
  end
end
