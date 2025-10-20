class PlayersController < ApplicationController
  def index
    @players = Player.includes(:player_summary)
                     .joins(:player_summary)
                     .where(player_summaries: { season: '2024-25' })
                     .order('player_summaries.avg_weekly_high DESC')
  end

  def show
    @player = Player.includes(:player_summary, :weekly_highs, :game_logs).find(params[:id])
    @weekly_highs = @player.weekly_highs.where(season: '2024-25').order(:week_number)
    @summary = @player.player_summary

    # Get all game logs for season stats
    all_games = @player.game_logs.where(season: '2024-25')

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
    season_start = Date.new(2024, 10, 21)
    @weekly_data = {}

    @weekly_highs.each do |wh|
      week_start = season_start + (wh.week_number - 1).weeks
      week_end = week_start + 6.days
      week_games = @player.game_logs.where(season: '2024-25', game_date: week_start..week_end).order(:game_date)

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
    @game_logs = @player.game_logs.where(season: '2024-25').order(:game_date)
  end
end
