# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_10_24_155944) do
  create_table "game_logs", force: :cascade do |t|
    t.integer "player_id", null: false
    t.date "game_date"
    t.integer "week_number"
    t.integer "points"
    t.integer "rebounds"
    t.integer "assists"
    t.integer "blocks"
    t.integer "steals"
    t.integer "fantasy_score"
    t.string "opponent"
    t.string "season"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "minutes_played", default: 0
    t.boolean "is_overtime", default: false
    t.index ["game_date"], name: "index_game_logs_on_game_date"
    t.index ["player_id", "game_date"], name: "index_game_logs_on_player_id_and_game_date"
    t.index ["player_id", "season"], name: "index_game_logs_on_player_id_and_season"
    t.index ["player_id"], name: "index_game_logs_on_player_id"
    t.index ["season", "game_date"], name: "index_game_logs_on_season_and_game_date"
    t.index ["season"], name: "index_game_logs_on_season"
  end

  create_table "player_summaries", force: :cascade do |t|
    t.integer "player_id", null: false
    t.string "season"
    t.decimal "avg_weekly_high"
    t.integer "non_zero_weeks"
    t.decimal "variance"
    t.integer "peak_score"
    t.integer "floor_score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "avg_score"
    t.decimal "differential"
    t.integer "total_fantasy_points"
    t.integer "games_played"
    t.integer "total_basketball_points"
    t.integer "projected_games"
    t.integer "projected_minutes"
    t.decimal "projected_fp"
    t.decimal "projected_fp_per_game"
    t.decimal "projected_fp_per_minute"
    t.decimal "last_3_days_avg", precision: 10, scale: 2, default: "0.0"
    t.decimal "last_7_days_avg", precision: 10, scale: 2, default: "0.0"
    t.decimal "last_14_days_avg", precision: 10, scale: 2, default: "0.0"
    t.integer "last_3_days_games", default: 0
    t.integer "last_7_days_games", default: 0
    t.integer "last_14_days_games", default: 0
    t.decimal "trend_7_days", precision: 10, scale: 2, default: "0.0"
    t.decimal "last_7_days_high", precision: 10, scale: 2, default: "0.0"
    t.index ["player_id", "season"], name: "index_player_summaries_on_player_id_and_season", unique: true
    t.index ["player_id"], name: "index_player_summaries_on_player_id"
    t.index ["season"], name: "index_player_summaries_on_season"
  end

  create_table "players", force: :cascade do |t|
    t.string "name"
    t.string "team"
    t.string "position"
    t.string "nba_id"
    t.decimal "ppg_2023_24"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "age"
    t.string "injury_status"
    t.index ["nba_id"], name: "index_players_on_nba_id", unique: true
  end

  create_table "weekly_highs", force: :cascade do |t|
    t.integer "player_id", null: false
    t.integer "week_number"
    t.string "season"
    t.integer "fantasy_score"
    t.integer "games_that_week"
    t.integer "best_game_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_weekly_highs_on_player_id"
  end

  add_foreign_key "game_logs", "players"
  add_foreign_key "player_summaries", "players"
  add_foreign_key "weekly_highs", "players"
end
