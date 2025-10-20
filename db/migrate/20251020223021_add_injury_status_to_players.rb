class AddInjuryStatusToPlayers < ActiveRecord::Migration[8.0]
  def change
    add_column :players, :injury_status, :string
  end
end
