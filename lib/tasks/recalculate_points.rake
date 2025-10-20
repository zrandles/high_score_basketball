namespace :nba do
  desc "Recalculate total_fantasy_points and total_basketball_points"
  task recalculate_points: :environment do
    season = "2023-24"

    puts "\n📊 Recalculating total fantasy points and total basketball points..."
    puts "=" * 60

    PlayerSummary.find_each.with_index do |summary, index|
      player = summary.player

      # Total fantasy points = sum of all weekly high fantasy scores
      total_fantasy = player.weekly_highs.where(season: season).sum(:fantasy_score)

      # Total basketball points = sum of points stat from ALL games
      total_bball_points = player.game_logs.where(season: season).sum(:points)

      # Games played count
      games_played = player.game_logs.where(season: season).count

      # Update summary
      summary.update!(
        total_fantasy_points: total_fantasy,
        total_basketball_points: total_bball_points,
        games_played: games_played
      )

      puts "[#{index + 1}/#{PlayerSummary.count}] #{player.name}: fantasy=#{total_fantasy}, bball=#{total_bball_points}, games=#{games_played}"
    end

    puts "\n✅ Recalculation complete!"
    puts "=" * 60
  end
end
