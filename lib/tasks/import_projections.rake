require 'csv'

namespace :nba do
  desc "Import season projections from CSV"
  task import_projections: :environment do
    file_path = ENV['FILE'] || 'tmp/projections.csv'
    season = ENV['SEASON'] || "2024-25"

    unless File.exist?(file_path)
      puts "❌ File not found: #{file_path}"
      puts "Usage: bin/rails nba:import_projections FILE=path/to/projections.csv"
      exit 1
    end

    puts "\n📊 Importing season projections from #{file_path}..."
    puts "Season: #{season}"
    puts "=" * 80

    updated = 0
    created = 0
    skipped = 0
    errors = []

    CSV.foreach(file_path, headers: true) do |row|
      player_name = row['Player']&.strip
      team = row['Team']&.strip

      next unless player_name

      # Extract injury status from player name (e.g., "LeBron James OUT")
      injury_status = nil
      if player_name =~ /(DTD|OUT|INJ|GTD|SUSP|NA)\s*$/i
        injury_status = $1.upcase
        player_name = player_name.gsub(/\s*(DTD|OUT|INJ|GTD|SUSP|NA)\s*$/i, '').strip
      end

      # Try to find player by name
      player = Player.find_by("LOWER(name) = ?", player_name.downcase)

      unless player
        # Try fuzzy match (without accents or special characters)
        normalized_name = player_name.gsub(/[^a-zA-Z\s]/, '').downcase
        player = Player.where("LOWER(REPLACE(name, 'ć', 'c')) = ?", normalized_name).first
      end

      unless player
        skipped += 1
        errors << "Player not found: #{player_name} (#{team})"
        next
      end

      # Update player team and injury status
      player.update(
        team: team,
        injury_status: injury_status
      )

      # Get or create player summary
      summary = player.player_summary || player.create_player_summary(season: season)

      # Parse projection data
      begin
        projected_games = row['GP']&.to_i
        projected_minutes = row['MIN']&.to_i
        projected_fp_per_game = row['FP/G']&.to_f
        projected_fp_per_minute = row['FP/MIN']&.to_f
        projected_fp = row['FP']&.to_f

        # Calculate FP if not provided (GP * FP/G)
        projected_fp ||= (projected_games && projected_fp_per_game) ?
                         (projected_games * projected_fp_per_game) : nil

        # Calculate FP/MIN if not provided (total MIN)
        if projected_fp_per_minute.nil? && projected_fp && projected_minutes && projected_minutes > 0
          total_minutes = projected_games * (projected_minutes.to_f / projected_games)
          projected_fp_per_minute = projected_fp / total_minutes
        end

        summary.update!(
          projected_games: projected_games,
          projected_minutes: projected_minutes,
          projected_fp: projected_fp,
          projected_fp_per_game: projected_fp_per_game,
          projected_fp_per_minute: projected_fp_per_minute
        )

        if summary.previously_new_record?
          created += 1
        else
          updated += 1
        end

        status_str = injury_status ? " [#{injury_status}]" : ""
        puts "[#{updated + created}/#{updated + created + skipped}] ✅ #{player.name} (#{team})#{status_str}: " \
             "#{projected_fp_per_game&.round(1)} FP/G, #{projected_games} GP"

      rescue => e
        errors << "Error updating #{player_name}: #{e.message}"
        skipped += 1
      end
    end

    puts "\n" + "=" * 80
    puts "✅ Import complete!"
    puts "   Updated: #{updated}"
    puts "   Created: #{created}"
    puts "   Skipped: #{skipped}"

    if errors.any?
      puts "\n⚠️  Errors/Warnings:"
      errors.first(20).each { |e| puts "   - #{e}" }
      puts "   ... and #{errors.size - 20} more" if errors.size > 20
    end
    puts "=" * 80
  end
end
