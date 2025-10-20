namespace :nba do
  desc "Remove playoff games and recalculate stats"
  task cleanup_playoffs: :environment do
    puts "Before: #{GameLog.count} total games"
    
    playoff_start = Date.parse('2024-04-15')
    deleted = GameLog.where('game_date >= ?', playoff_start).delete_all
    
    puts "Deleted #{deleted} playoff games (after #{playoff_start})"
    puts "After: #{GameLog.count} total games"
    
    # Clear calculated data
    WeeklyHigh.delete_all
    PlayerSummary.delete_all
    puts "Cleared weekly highs and summaries"
    
    # Recalculate everything
    puts "\nRecalculating weekly highs..."
    Player.find_each do |player|
      player.game_logs.group_by(&:week_number).each do |week, games|
        next if games.empty?
        best_game = games.max_by(&:fantasy_score)
        WeeklyHigh.create!(
          player: player,
          week_number: week,
          season: '2023-24',
          fantasy_score: best_game.fantasy_score,
          games_that_week: games.count,
          best_game: best_game
        )
      end
    end
    
    puts "Recalculating player summaries..."
    Player.find_each do |player|
      weekly_highs = player.weekly_highs.where(season: '2023-24')
      next if weekly_highs.empty?
      
      fantasy_scores = weekly_highs.pluck(:fantasy_score)
      
      PlayerSummary.create!(
        player: player,
        season: '2023-24',
        avg_weekly_high: fantasy_scores.sum / fantasy_scores.size.to_f,
        non_zero_weeks: fantasy_scores.size,
        variance: calculate_variance(fantasy_scores),
        peak_score: fantasy_scores.max,
        floor_score: fantasy_scores.min,
        avg_score: player.game_logs.average(:fantasy_score).to_f.round(1),
        total_fantasy_points: fantasy_scores.sum,
        total_basketball_points: player.game_logs.sum(:points),
        games_played: player.game_logs.count
      )
    end
    
    puts "\nDone! #{PlayerSummary.count} players updated"
  end
  
  def calculate_variance(scores)
    return 0 if scores.empty?
    mean = scores.sum / scores.size.to_f
    sum_of_squares = scores.map { |x| (x - mean) ** 2 }.sum
    Math.sqrt(sum_of_squares / scores.size).round(1)
  end
end
