class AddMinutesPlayedToGameLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :game_logs, :minutes_played, :integer, default: 0
    add_column :game_logs, :is_overtime, :boolean, default: false
  end
end
