class CreatePlayerSummaries < ActiveRecord::Migration[8.0]
  def change
    create_table :player_summaries do |t|
      t.references :player, null: false, foreign_key: true
      t.string :season
      t.decimal :avg_weekly_high
      t.integer :non_zero_weeks
      t.decimal :variance
      t.integer :peak_score
      t.integer :floor_score

      t.timestamps
    end
  end
end
