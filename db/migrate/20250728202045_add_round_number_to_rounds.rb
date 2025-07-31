class AddRoundNumberToRounds < ActiveRecord::Migration[7.1]
  def change
    add_column :rounds, :round_number, :integer
  end
end
