namespace :nba do
  desc "Quick recalculate avg_score and differential (skip age)"
  task quick_recalculate: :environment do
    season = "2023-24"

    puts "\n📊 Quick recalculating avg_score and differential..."
    puts "=" * 60

    PlayerSummary.find_each.with_index do |summary, index|
      player = summary.player

      # Calculate avg_score: average of ALL game logs
      game_logs = player.game_logs.where(season: season)
      if game_logs.any?
        avg_score = game_logs.average(:fantasy_score).to_f

        # Calculate differential: avg_weekly_high - avg_score
        differential = summary.avg_weekly_high.to_f - avg_score

        # Update summary (skip age for speed)
        summary.update!(
          avg_score: avg_score,
          differential: differential
        )

        puts "[#{index + 1}/#{PlayerSummary.count}] #{player.name}: avg=#{avg_score.round(1)}, diff=#{differential.round(1)}"
      end
    end

    puts "\n✅ Quick recalculation complete!"
    puts "=" * 60
  end
end
