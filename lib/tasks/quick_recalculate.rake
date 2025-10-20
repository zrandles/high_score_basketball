namespace :nba do
  desc "Quick recalculate avg_score, differential, and games_played (skip age)"
  task quick_recalculate: :environment do
    season = ENV['SEASON'] || "2024-25"

    # Season start date for week calculations
    season_start = season == "2024-25" ? Date.new(2024, 10, 21) : Date.new(2023, 10, 23)

    puts "\n📊 Quick recalculating avg_score, differential (weekly upside), and games_played for #{season}..."
    puts "=" * 60

    PlayerSummary.where(season: season).find_each.with_index(1) do |summary, index|
      player = summary.player

      # Calculate avg_score: average of ALL game logs
      game_logs = player.game_logs.where(season: season)
      if game_logs.any?
        avg_score = game_logs.average(:fantasy_score).to_f
        games_played = game_logs.count

        # Calculate differential: average of weekly (high - weekly_average) values
        weekly_highs = player.weekly_highs.where(season: season)
        weekly_upsides = []

        weekly_highs.each do |wh|
          # Get all games for this week using week_number
          week_games = player.game_logs.where(season: season, week_number: wh.week_number)

          if week_games.any?
            week_avg = week_games.average(:fantasy_score).to_f
            weekly_upside = wh.fantasy_score - week_avg
            weekly_upsides << weekly_upside
          end
        end

        differential = weekly_upsides.any? ? (weekly_upsides.sum / weekly_upsides.size) : 0.0

        # Update summary (skip age for speed)
        summary.update!(
          avg_score: avg_score,
          differential: differential,
          games_played: games_played
        )

        puts "[#{index}/#{PlayerSummary.where(season: season).count}] #{player.name}: avg=#{avg_score.round(1)}, upside=#{differential.round(1)}, GP=#{games_played}"
      end
    end

    puts "\n✅ Quick recalculation complete!"
    puts "=" * 60
  end
end
