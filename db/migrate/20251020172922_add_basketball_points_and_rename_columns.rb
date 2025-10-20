class AddBasketballPointsAndRenameColumns < ActiveRecord::Migration[8.0]
  def change
    rename_column :player_summaries, :total_points, :total_fantasy_points
    add_column :player_summaries, :total_basketball_points, :integer
  end
end
