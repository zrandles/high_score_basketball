class PlayersController < ApplicationController
  def index
    @players = Player.includes(:player_summary)
                     .joins(:player_summary)
                     .where(player_summaries: { season: '2025-26' })
                     .order(Arel.sql('player_summaries.last_7_days_avg DESC NULLS LAST'))

    # Preload recent game logs for ALL players in optimized queries
    # This eliminates N+1 queries in the view (was 384 queries per page load!)
    player_ids = @players.pluck(:id)
    season = '2025-26'
    cutoff_date = 14.days.ago

    # Load recent games for hot/cold streak calculation
    @recent_games_by_player = GameLog.where(player_id: player_ids, season: season)
                                     .where('game_date >= ?', 7.days.ago)
                                     .order(:player_id, :game_date)
                                     .group_by(&:player_id)

    # Load last 14 games for sparklines
    @last_14_games_by_player = GameLog.where(player_id: player_ids, season: season)
                                      .order(Arel.sql('player_id, game_date DESC'))
                                      .group_by(&:player_id)
                                      .transform_values { |logs| logs.first(14).reverse }

    # Calculate percentiles for filtering
    @percentiles = calculate_percentiles(@players)
  end

  def show
    @player = Player.includes(:player_summary, :weekly_highs, :game_logs).find(params[:id])
    @weekly_highs = @player.weekly_highs.where(season: '2025-26').order(:week_number)
    @summary = @player.player_summary

    # Handle case where player has no summary (redirect with notice)
    unless @summary
      redirect_to players_path, alert: "Player summary not available for #{@player.name}"
      return
    end

    # Get all game logs for season stats
    all_games = @player.game_logs.where(season: '2025-26')

    # Calculate season totals and per-game averages
    @total_games = all_games.count
    if @total_games > 0
      @total_points = all_games.sum(:points)
      @fantasy_ppg = all_games.average(:fantasy_score).to_f
      @points_per_game = all_games.average(:points).to_f
      @rebounds_per_game = all_games.average(:rebounds).to_f
      @assists_per_game = all_games.average(:assists).to_f
      @blocks_per_game = all_games.average(:blocks).to_f
      @steals_per_game = all_games.average(:steals).to_f
    else
      @total_points = @fantasy_ppg = @points_per_game = @rebounds_per_game = 0
      @assists_per_game = @blocks_per_game = @steals_per_game = 0
    end

    # Calculate weekly averages and scores for upside calculation
    @weekly_data = {}

    @weekly_highs.each do |wh|
      # Use week_number field to match games (don't calculate date ranges)
      week_games = @player.game_logs.where(season: '2025-26', week_number: wh.week_number).order(:game_date)

      if week_games.any?
        week_avg = week_games.average(:fantasy_score).to_f
        scores = week_games.pluck(:fantasy_score)
        @weekly_data[wh.week_number] = {
          average: week_avg,
          upside: wh.fantasy_score - week_avg,
          scores: scores
        }
      end
    end
  end

  def raw_data
    @player = Player.includes(:game_logs).find(params[:id])
    @game_logs = @player.game_logs.where(season: '2025-26').order(:game_date)
  end

  private

  def calculate_percentiles(players)
    percentiles = {}

    # Already have player_summaries loaded via includes - don't query again
    summaries = players.map(&:player_summary).compact

    columns = {
      'last_7_days_avg' => 'Last 7d Avg',
      'trend_7_days' => 'Trend %',
      'last_7_days_high' => 'Last 7d High',
      'avg_score' => 'Season Avg',
      'last_14_days_avg' => 'Last 14d Avg',
      'last_7_days_games' => 'Games (7d)',
      'last_14_days_games' => 'Games (14d)'
    }

    columns.each do |col, name|
      # Use public_send instead of send for better security
      values = summaries.map { |s| s.public_send(col) }
                       .compact
                       .sort

      percentiles[col] = {
        '0' => values.first || 0,
        '25' => values[(values.length * 0.25).to_i] || 0,
        '50' => values[(values.length * 0.50).to_i] || 0,
        '75' => values[(values.length * 0.75).to_i] || 0,
        '90' => values[(values.length * 0.90).to_i] || 0,
        '95' => values[(values.length * 0.95).to_i] || 0,
        '100' => values.last || 0
      }
    end

    percentiles
  end
end
