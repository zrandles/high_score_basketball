class Player < ApplicationRecord
  has_many :game_logs, dependent: :destroy
  has_many :weekly_highs, dependent: :destroy
  has_one :player_summary, dependent: :destroy

  validates :name, presence: true
  validates :nba_id, presence: true, uniqueness: true
end
