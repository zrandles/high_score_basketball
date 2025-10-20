class PlayersController < ApplicationController
  def index
    @players = Player.includes(:player_summary)
                     .joins(:player_summary)
                     .where(player_summaries: { season: '2024-25' })
                     .order('player_summaries.avg_weekly_high DESC')
  end

  def show
    @player = Player.includes(:player_summary, :weekly_highs).find(params[:id])
    @weekly_highs = @player.weekly_highs.where(season: '2024-25').order(:week_number)
    @summary = @player.player_summary
  end

  def raw_data
    @player = Player.includes(:game_logs).find(params[:id])
    @game_logs = @player.game_logs.where(season: '2024-25').order(:game_date)
  end
end
