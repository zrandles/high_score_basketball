class AddAvgScoreDifferentialAndAge < ActiveRecord::Migration[8.0]
  def change
    add_column :player_summaries, :avg_score, :decimal
    add_column :player_summaries, :differential, :decimal
    add_column :players, :age, :integer
  end
end
