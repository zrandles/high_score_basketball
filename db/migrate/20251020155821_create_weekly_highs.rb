class CreateWeeklyHighs < ActiveRecord::Migration[8.0]
  def change
    create_table :weekly_highs do |t|
      t.references :player, null: false, foreign_key: true
      t.integer :week_number
      t.string :season
      t.integer :fantasy_score
      t.integer :games_that_week
      t.integer :best_game_id

      t.timestamps
    end
  end
end
