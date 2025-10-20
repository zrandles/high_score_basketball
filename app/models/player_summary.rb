class PlayerSummary < ApplicationRecord
  belongs_to :player

  validates :season, presence: true
  validates :season, uniqueness: { scope: :player_id }
end
