require 'net/http'
require 'json'

class NbaApiService
  BASE_URL = 'https://stats.nba.com/stats'
  HEADERS = {
    'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer' => 'https://www.nba.com/',
    'Origin' => 'https://www.nba.com',
    'Accept' => 'application/json, text/plain, */*',
    'Accept-Language' => 'en-US,en;q=0.9',
    'x-nba-stats-origin' => 'stats',
    'x-nba-stats-token' => 'true'
  }.freeze

  def self.fetch_players_with_min_ppg(min_ppg: 10, season: '2023-24')
    url = "#{BASE_URL}/leaguedashplayerstats?College=&Conference=&Country=&DateFrom=&DateTo=&Division=&DraftPick=&DraftYear=&GameScope=&GameSegment=&Height=&LastNGames=0&LeagueID=00&Location=&MeasureType=Base&Month=0&OpponentTeamID=0&Outcome=&PORound=0&PaceAdjust=N&PerMode=PerGame&Period=0&PlayerExperience=&PlayerPosition=&PlusMinus=N&Rank=N&Season=#{season}&SeasonSegment=&SeasonType=Regular+Season&ShotClockRange=&StarterBench=&TeamID=0&TwoWay=0&VsConference=&VsDivision=&Weight="

    Rails.logger.info "Fetching players from NBA API for season #{season} with min PPG #{min_ppg}"

    response = make_request(url)
    return [] unless response

    data = JSON.parse(response.body)
    headers = data['resultSets'][0]['headers']
    rows = data['resultSets'][0]['rowSet']

    # Find column indexes
    player_id_idx = headers.index('PLAYER_ID')
    player_name_idx = headers.index('PLAYER_NAME')
    team_idx = headers.index('TEAM_ABBREVIATION')
    pts_idx = headers.index('PTS')

    # Filter players by min PPG and map to hash
    players = rows.select { |row| row[pts_idx].to_f >= min_ppg }.map do |row|
      {
        nba_id: row[player_id_idx].to_s,
        name: row[player_name_idx],
        team: row[team_idx],
        ppg: row[pts_idx].to_f
      }
    end

    Rails.logger.info "Found #{players.count} players averaging #{min_ppg}+ PPG"
    players

  rescue => e
    Rails.logger.error "Error fetching players: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    []
  end

  def self.fetch_player_game_logs(nba_id, season: '2023-24')
    url = "#{BASE_URL}/playergamelog?DateFrom=&DateTo=&LeagueID=00&PlayerID=#{nba_id}&Season=#{season}&SeasonType=Regular+Season"

    Rails.logger.info "Fetching game logs for player #{nba_id}"

    response = make_request(url)
    return [] unless response

    data = JSON.parse(response.body)
    headers = data['resultSets'][0]['headers']
    rows = data['resultSets'][0]['rowSet']

    # Find column indexes
    game_date_idx = headers.index('GAME_DATE')
    matchup_idx = headers.index('MATCHUP')
    pts_idx = headers.index('PTS')
    reb_idx = headers.index('REB')
    ast_idx = headers.index('AST')
    blk_idx = headers.index('BLK')
    stl_idx = headers.index('STL')

    # Map to game log hashes
    game_logs = rows.map do |row|
      {
        game_date: Date.parse(row[game_date_idx]),
        opponent: extract_opponent(row[matchup_idx]),
        points: row[pts_idx].to_i,
        rebounds: row[reb_idx].to_i,
        assists: row[ast_idx].to_i,
        blocks: row[blk_idx].to_i,
        steals: row[stl_idx].to_i
      }
    end

    Rails.logger.info "Found #{game_logs.count} games for player #{nba_id}"
    game_logs

  rescue => e
    Rails.logger.error "Error fetching game logs for player #{nba_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    []
  end

  private

  def self.make_request(url)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30
    http.open_timeout = 30

    request = Net::HTTP::Get.new(uri.request_uri)
    HEADERS.each { |key, value| request[key] = value }

    # Rate limiting - sleep before request
    sleep(0.5)

    response = http.request(request)

    if response.code == '200'
      response
    else
      Rails.logger.error "API request failed with status #{response.code}: #{response.body}"
      nil
    end
  rescue => e
    Rails.logger.error "HTTP request error: #{e.message}"
    nil
  end

  def self.extract_opponent(matchup)
    # Matchup format: "LAL vs. BOS" or "LAL @ BOS"
    # Extract the opponent team
    parts = matchup.split(/\s+(?:vs\.|@)\s+/)
    parts[1] || 'UNK'
  end
end
