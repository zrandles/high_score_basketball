class CreateGameLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :game_logs do |t|
      t.references :player, null: false, foreign_key: true
      t.date :game_date
      t.integer :week_number
      t.integer :points
      t.integer :rebounds
      t.integer :assists
      t.integer :blocks
      t.integer :steals
      t.integer :fantasy_score
      t.string :opponent
      t.string :season

      t.timestamps
    end
  end
end
