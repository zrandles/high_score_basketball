class AddProjectedStatsToPlayerSummaries < ActiveRecord::Migration[8.0]
  def change
    add_column :player_summaries, :projected_games, :integer
    add_column :player_summaries, :projected_minutes, :integer
    add_column :player_summaries, :projected_fp, :decimal
    add_column :player_summaries, :projected_fp_per_game, :decimal
    add_column :player_summaries, :projected_fp_per_minute, :decimal
  end
end
