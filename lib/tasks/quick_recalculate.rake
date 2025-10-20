namespace :nba do
  desc "Quick recalculate avg_score, differential, and games_played (skip age)"
  task quick_recalculate: :environment do
    season = ENV['SEASON'] || "2024-25"

    puts "\n📊 Quick recalculating avg_score, differential, and games_played for #{season}..."
    puts "=" * 60

    PlayerSummary.where(season: season).find_each.with_index(1) do |summary, index|
      player = summary.player

      # Calculate avg_score: average of ALL game logs
      game_logs = player.game_logs.where(season: season)
      if game_logs.any?
        avg_score = game_logs.average(:fantasy_score).to_f
        games_played = game_logs.count

        # Calculate differential: avg_weekly_high - avg_score
        differential = summary.avg_weekly_high.to_f - avg_score

        # Update summary (skip age for speed)
        summary.update!(
          avg_score: avg_score,
          differential: differential,
          games_played: games_played
        )

        puts "[#{index}/#{PlayerSummary.where(season: season).count}] #{player.name}: avg=#{avg_score.round(1)}, diff=#{differential.round(1)}, GP=#{games_played}"
      end
    end

    puts "\n✅ Quick recalculation complete!"
    puts "=" * 60
  end
end
