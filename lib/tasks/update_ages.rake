require 'net/http'
require 'json'

namespace :nba do
  desc "Update player ages from NBA Stats API"
  task update_ages: :environment do
    season = ENV['SEASON'] || "2024-25"

    puts "\n📊 Fetching player ages from NBA Stats API..."
    puts "Season: #{season}"
    puts "=" * 80

    # NBA Stats API endpoint
    url = URI("https://stats.nba.com/stats/leaguedashplayerstats?Season=#{season}&SeasonType=Regular+Season&PerMode=Totals")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
    request["Referer"] = "https://www.nba.com/"
    request["Origin"] = "https://www.nba.com"

    response = http.request(request)

    unless response.code == "200"
      puts "❌ Failed to fetch data from NBA Stats API"
      puts "Response code: #{response.code}"
      exit 1
    end

    data = JSON.parse(response.body)
    headers = data['resultSets'][0]['headers']
    rows = data['resultSets'][0]['rowSet']

    # Find column indices
    player_name_idx = headers.index('PLAYER_NAME')
    age_idx = headers.index('PLAYER_AGE')

    unless player_name_idx && age_idx
      puts "❌ Could not find required columns in API response"
      exit 1
    end

    updated = 0
    skipped = 0
    errors = []

    rows.each do |row|
      player_name = row[player_name_idx]
      age = row[age_idx]

      next unless player_name && age

      # Try to find player by name
      player = Player.find_by("LOWER(name) = ?", player_name.downcase)

      unless player
        # Try fuzzy match (without accents or special characters)
        normalized_name = player_name.gsub(/[^a-zA-Z\s]/, '').downcase
        player = Player.where("LOWER(REPLACE(REPLACE(name, 'ć', 'c'), 'č', 'c')) LIKE ?", "%#{normalized_name}%").first
      end

      if player
        player.update(age: age)
        updated += 1
        puts "[#{updated}] ✅ #{player.name}: #{age} years old"
      else
        skipped += 1
        errors << "Player not found: #{player_name} (age #{age})"
      end
    end

    puts "\n" + "=" * 80
    puts "✅ Age update complete!"
    puts "   Updated: #{updated}"
    puts "   Skipped: #{skipped}"

    if errors.any? && errors.size <= 20
      puts "\n⚠️  Players not found:"
      errors.each { |e| puts "   - #{e}" }
    elsif errors.size > 20
      puts "\n⚠️  #{errors.size} players not found in database"
    end
    puts "=" * 80
  end
end
