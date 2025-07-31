class AddStatusToRound < ActiveRecord::Migration[7.1]
  def change
    add_column :rounds, :status, :string
  end
end
