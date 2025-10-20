class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :players do |t|
      t.string :name
      t.string :team
      t.string :position
      t.string :nba_id
      t.decimal :ppg_2023_24

      t.timestamps
    end
  end
end
