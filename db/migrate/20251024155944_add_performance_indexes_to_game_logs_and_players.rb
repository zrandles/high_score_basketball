class AddPerformanceIndexesToGameLogsAndPlayers < ActiveRecord::Migration[8.0]
  def change
    # Critical indexes for game_logs - these will dramatically improve query performance
    add_index :game_logs, :season
    add_index :game_logs, :game_date
    add_index :game_logs, [:player_id, :season]
    add_index :game_logs, [:player_id, :game_date]
    add_index :game_logs, [:season, :game_date]

    # Index for player_summaries
    add_index :player_summaries, :season
    add_index :player_summaries, [:player_id, :season], unique: true

    # Make nba_id unique index on players (enforce data integrity)
    add_index :players, :nba_id, unique: true
  end
end
