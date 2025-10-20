namespace :nba do
  desc "Fix weekly highs by recalculating from game logs"
  task fix_weekly_highs: :environment do
    season = ENV['SEASON'] || "2024-25"

    puts "\n🔧 Fixing weekly highs for #{season} season..."
    puts "=" * 60

    # Delete all existing weekly highs for this season
    deleted_count = WeeklyHigh.where(season: season).delete_all
    puts "🗑️  Deleted #{deleted_count} existing weekly high records"

    # Recalculate for each player
    Player.find_each.with_index(1) do |player, index|
      weeks = player.game_logs.where(season: season).pluck(:week_number).uniq.sort

      weeks.each do |week|
        week_games = player.game_logs.where(season: season, week_number: week)
        next if week_games.empty?

        # Find the actual maximum fantasy score
        max_score = week_games.maximum(:fantasy_score)
        best_game = week_games.find_by(fantasy_score: max_score)

        WeeklyHigh.create!(
          player: player,
          week_number: week,
          season: season,
          fantasy_score: max_score,
          games_that_week: week_games.count,
          best_game: best_game
        )
      end

      print "\r[#{index}/#{Player.count}] #{player.name}"
    end

    puts "\n\n✅ Fixed weekly highs for all players!"
    puts "   Total weekly highs: #{WeeklyHigh.where(season: season).count}"
    puts "=" * 60
  end
end
