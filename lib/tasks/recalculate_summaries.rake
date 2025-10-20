namespace :nba do
  desc "Recalculate player summaries with avg_score, differential, and age"
  task recalculate_summaries: :environment do
    season = "2023-24"

    puts "\n📊 Recalculating player summaries with new fields..."
    puts "=" * 60

    Player.find_each.with_index do |player, index|
      summary = player.player_summary
      next unless summary

      # Calculate avg_score: average of ALL game logs
      game_logs = player.game_logs.where(season: season)
      if game_logs.any?
        avg_score = game_logs.average(:fantasy_score).to_f

        # Calculate differential: avg_weekly_high - avg_score
        differential = summary.avg_weekly_high.to_f - avg_score

        # Update summary
        summary.update!(
          avg_score: avg_score,
          differential: differential
        )

        # Estimate age based on NBA experience
        # NBA API doesn't easily provide age, so we'll use a common API endpoint
        # For now, use a placeholder that can be updated later
        # Typical NBA players range from 19-40 years old
        # We'll fetch from the commonplayerinfo endpoint
        age = fetch_player_age(player.nba_id)
        player.update!(age: age) if age

        puts "[#{index + 1}/#{Player.count}] #{player.name}: avg_score=#{avg_score.round(1)}, differential=#{differential.round(1)}, age=#{age || 'N/A'}"

        # Rate limiting
        sleep(0.3) if age # Only sleep if we made an API call
      end
    end

    puts "\n✅ Recalculation complete!"
    puts "=" * 60
  end

  def fetch_player_age(nba_id)
    url = "https://stats.nba.com/stats/commonplayerinfo?LeagueID=00&PlayerID=#{nba_id}"

    response = NbaApiService.send(:make_request, url)
    return nil unless response

    data = JSON.parse(response.body)
    headers = data['resultSets'][0]['headers']
    row = data['resultSets'][0]['rowSet'][0]

    return nil unless row

    # Try to get birthdate and calculate age
    birthdate_idx = headers.index('BIRTHDATE')
    if birthdate_idx && row[birthdate_idx]
      birthdate = Date.parse(row[birthdate_idx])
      age = ((Date.today - birthdate).to_i / 365.25).floor
      return age
    end

    nil
  rescue => e
    Rails.logger.error "Error fetching age for player #{nba_id}: #{e.message}"
    nil
  end
end
