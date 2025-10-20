class AddTotalPointsAndGamesPlayedToPlayerSummaries < ActiveRecord::Migration[8.0]
  def change
    add_column :player_summaries, :total_points, :integer
    add_column :player_summaries, :games_played, :integer
  end
end
