class AddRecentPerformanceToPlayerSummaries < ActiveRecord::Migration[8.0]
  def change
    add_column :player_summaries, :last_3_days_avg, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :player_summaries, :last_7_days_avg, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :player_summaries, :last_14_days_avg, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :player_summaries, :last_3_days_games, :integer, default: 0
    add_column :player_summaries, :last_7_days_games, :integer, default: 0
    add_column :player_summaries, :last_14_days_games, :integer, default: 0
    add_column :player_summaries, :trend_7_days, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :player_summaries, :last_7_days_high, :decimal, precision: 10, scale: 2, default: 0.0
  end
end
