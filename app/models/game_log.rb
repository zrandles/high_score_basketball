class GameLog < ApplicationRecord
  belongs_to :player

  validates :game_date, :week_number, :season, presence: true
  validates :points, :rebounds, :assists, :blocks, :steals, :fantasy_score, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_validation :calculate_fantasy_score, if: -> { points_changed? || rebounds_changed? || assists_changed? || blocks_changed? || steals_changed? }

  private

  def calculate_fantasy_score
    self.fantasy_score = points.to_i + rebounds.to_i + (2 * assists.to_i) + (3 * blocks.to_i) + (3 * steals.to_i)
  end
end
