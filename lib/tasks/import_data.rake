namespace :nba do
  desc "Import 2023-24 NBA season data for players averaging 10+ PPG"
  task import_2023_24: :environment do
    season = "2023-24"
    season_start = Date.parse("2023-10-24")
    min_ppg = 10

    puts "\n🏀 Starting NBA data import for #{season} season"
    puts "=" * 60

    # Step 1: Fetch players
    puts "\n📋 Step 1: Fetching players averaging #{min_ppg}+ PPG..."
    players_data = NbaApiService.fetch_players_with_min_ppg(min_ppg: min_ppg, season: season)

    if players_data.empty?
      puts "❌ No players found. Exiting."
      exit
    end

    puts "✅ Found #{players_data.count} players"

    # Step 2: Import game logs for each player
    puts "\n📊 Step 2: Importing game logs..."
    players_data.each_with_index do |player_data, index|
      puts "\n[#{index + 1}/#{players_data.count}] #{player_data[:name]} (#{player_data[:team]})"

      # Create or find player
      player = Player.find_or_create_by!(nba_id: player_data[:nba_id]) do |p|
        p.name = player_data[:name]
        p.team = player_data[:team]
        p.ppg_2023_24 = player_data[:ppg]
      end

      # Fetch game logs
      game_logs_data = NbaApiService.fetch_player_game_logs(player_data[:nba_id], season: season)

      if game_logs_data.empty?
        puts "  ⚠️  No game logs found"
        next
      end

      # Create game logs
      game_logs_created = 0
      game_logs_data.each do |log_data|
        week_number = calculate_week_number(log_data[:game_date], season_start)

        GameLog.create!(
          player: player,
          game_date: log_data[:game_date],
          week_number: week_number,
          season: season,
          points: log_data[:points],
          rebounds: log_data[:rebounds],
          assists: log_data[:assists],
          blocks: log_data[:blocks],
          steals: log_data[:steals],
          opponent: log_data[:opponent],
          fantasy_score: 0  # Will be calculated by model callback
        )
        game_logs_created += 1
      end

      puts "  ✅ Imported #{game_logs_created} games"

      # Rate limiting between players
      sleep(0.5) unless index == players_data.count - 1
    end

    # Step 3: Calculate weekly highs
    puts "\n📈 Step 3: Calculating weekly highs..."
    Player.find_each do |player|
      weeks = player.game_logs.where(season: season).pluck(:week_number).uniq.sort

      weeks.each do |week|
        week_games = player.game_logs.where(season: season, week_number: week).order(fantasy_score: :desc)
        next if week_games.empty?

        best_game = week_games.first

        WeeklyHigh.create!(
          player: player,
          week_number: week,
          season: season,
          fantasy_score: best_game.fantasy_score,
          games_that_week: week_games.count,
          best_game: best_game
        )
      end
    end

    puts "✅ Created weekly highs for all players"

    # Step 4: Calculate player summaries
    puts "\n📊 Step 4: Calculating player summaries..."
    Player.find_each do |player|
      weekly_highs = player.weekly_highs.where(season: season)
      next if weekly_highs.empty?

      scores = weekly_highs.pluck(:fantasy_score)
      non_zero_weeks = scores.count { |s| s > 0 }

      if non_zero_weeks > 0
        avg_weekly_high = scores.sum.to_f / non_zero_weeks
        variance = calculate_variance(scores)
        peak_score = scores.max
        floor_score = scores.min
      else
        avg_weekly_high = 0
        variance = 0
        peak_score = 0
        floor_score = 0
      end

      PlayerSummary.create!(
        player: player,
        season: season,
        avg_weekly_high: avg_weekly_high,
        non_zero_weeks: non_zero_weeks,
        variance: variance,
        peak_score: peak_score,
        floor_score: floor_score
      )
    end

    puts "✅ Created player summaries for all players"

    # Final summary
    puts "\n" + "=" * 60
    puts "🎉 Import complete!"
    puts "\nStats:"
    puts "  Players: #{Player.count}"
    puts "  Game Logs: #{GameLog.count}"
    puts "  Weekly Highs: #{WeeklyHigh.count}"
    puts "  Player Summaries: #{PlayerSummary.count}"
    puts "=" * 60
  end

  def calculate_week_number(game_date, season_start)
    ((game_date - season_start).to_i / 7) + 1
  end

  def calculate_variance(scores)
    return 0 if scores.empty?

    mean = scores.sum.to_f / scores.count
    sum_of_squares = scores.map { |score| (score - mean) ** 2 }.sum
    variance = sum_of_squares / scores.count

    variance
  end
end
