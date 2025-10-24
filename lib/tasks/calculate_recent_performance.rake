namespace :basketball do
  desc "Calculate recent performance metrics for all players"
  task calculate_recent_performance: :environment do
    season = '2025-26'
    cutoff_date = Date.today

    # For development/testing, use the most recent game date in the database
    latest_game = GameLog.where(season: season).maximum(:game_date)
    if latest_game
      cutoff_date = latest_game
      puts "Using latest game date as cutoff: #{cutoff_date}"
    else
      puts "No games found for season #{season}"
      exit
    end

    Player.includes(:player_summary, :game_logs).find_each do |player|
      summary = player.player_summary
      next unless summary&.season == season

      # Get all game logs for this season
      all_games = player.game_logs.where(season: season).order(:game_date)

      # Calculate for different time periods
      [3, 7, 14].each do |days|
        start_date = cutoff_date - days.days
        recent_games = all_games.where('game_date > ? AND game_date <= ?', start_date, cutoff_date)

        games_count = recent_games.count
        avg = recent_games.any? ? recent_games.average(:fantasy_score).to_f.round(2) : 0.0

        case days
        when 3
          summary.last_3_days_games = games_count
          summary.last_3_days_avg = avg
        when 7
          summary.last_7_days_games = games_count
          summary.last_7_days_avg = avg
          summary.last_7_days_high = recent_games.any? ? recent_games.maximum(:fantasy_score).to_f.round(2) : 0.0

          # Calculate trend (recent 7 days vs season average)
          if summary.avg_score && summary.avg_score > 0 && avg > 0
            summary.trend_7_days = ((avg - summary.avg_score) / summary.avg_score * 100).round(2)
          else
            summary.trend_7_days = 0.0
          end
        when 14
          summary.last_14_days_games = games_count
          summary.last_14_days_avg = avg
        end
      end

      summary.save!
    end

    puts "✅ Recent performance calculated for all players"
    puts "   Cutoff date: #{cutoff_date}"
    puts "   Season: #{season}"
  end
end
