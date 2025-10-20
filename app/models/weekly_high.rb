class WeeklyHigh < ApplicationRecord
  belongs_to :player
  belongs_to :best_game, class_name: 'GameLog', foreign_key: 'best_game_id', optional: true

  validates :week_number, :season, :fantasy_score, presence: true
  validates :week_number, uniqueness: { scope: [:player_id, :season] }
end
