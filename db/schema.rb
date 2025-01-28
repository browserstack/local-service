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

ActiveRecord::Schema[7.1].define(version: 2025_01_27_092045) do
  create_table "custom_repeater_allocations", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "repeater_id", null: false
    t.bigint "user_or_group_id", null: false
    t.string "association_type", null: false
    t.string "allocation_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["repeater_id"], name: "index_custom_repeater_allocations_on_repeater_id"
    t.index ["user_or_group_id", "repeater_id"], name: "index_custom_repeater_allocations_on_user_or_group_and_repeater", unique: true
  end

  create_table "dedicated_repeater_allocations", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "repeater_id", null: false
    t.bigint "repeater_ip_id", null: false
    t.bigint "user_or_group_id", null: false
    t.string "association_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["repeater_id"], name: "index_dedicated_repeater_allocations_on_repeater_id"
    t.index ["repeater_ip_id"], name: "index_dedicated_repeater_allocations_on_repeater_ip_id"
    t.index ["user_or_group_id", "repeater_id"], name: "index_dedicated_repeater_allocations", unique: true
  end

  create_table "local_hub_repeater_regions", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "user_or_group_id", null: false
    t.string "association_type", null: false
    t.string "hub_repeater_sessions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_or_group_id", "association_type"], name: "index_local_hub_repeater_regions_on_user_or_group_and_type", unique: true
  end

  create_table "local_tunnel_info", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "user_or_group_id", null: false
    t.string "auth_token", null: false
    t.string "local_identifier", null: false
    t.boolean "force_local", default: false
    t.string "username"
    t.integer "rotation_limit"
    t.integer "rotation_counter"
    t.string "region"
    t.string "proxy_type"
    t.string "tunnel_type"
    t.string "hashed_identifier", limit: 40, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auth_token"], name: "index_local_tunnel_info_on_auth_token", unique: true
    t.index ["hashed_identifier"], name: "index_local_tunnel_info_on_hashed_identifier", unique: true
  end

  create_table "repeater_ips", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "repeater_id", null: false
    t.string "private_ip", null: false
    t.string "public_ip", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["private_ip"], name: "index_repeater_ips_on_private_ip", unique: true
    t.index ["public_ip"], name: "index_repeater_ips_on_public_ip", unique: true
    t.index ["repeater_id"], name: "index_repeater_ips_on_repeater_id"
  end

  create_table "repeater_regions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "dc_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dc_name"], name: "index_repeater_regions_on_dc_name", unique: true
  end

  create_table "repeater_sub_regions", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "repeater_region_id", null: false
    t.string "dc_name", null: false
    t.float "latitude", null: false
    t.float "longitude", null: false
    t.string "state", default: "up", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dc_name"], name: "index_repeater_sub_regions_on_dc_name", unique: true
    t.index ["repeater_region_id"], name: "index_repeater_sub_regions_on_repeater_region_id"
    t.index ["state"], name: "index_repeater_sub_regions_on_state"
  end

  create_table "repeaters", charset: "utf8mb3", force: :cascade do |t|
    t.string "host_name", null: false
    t.bigint "repeater_region_id", null: false
    t.bigint "repeater_sub_region_id", null: false
    t.string "state", default: "active", null: false
    t.string "repeater_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["host_name"], name: "index_repeaters_on_host_name", unique: true
    t.index ["repeater_region_id"], name: "index_repeaters_on_repeater_region_id"
    t.index ["repeater_sub_region_id"], name: "index_repeaters_on_repeater_sub_region_id"
    t.index ["state"], name: "index_repeaters_on_state"
  end

  create_table "tunnel_repeaters", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "repeater_id", null: false
    t.bigint "tunnel_id", null: false
    t.bigint "user_or_group_id", null: false
    t.string "association_type", null: false
    t.boolean "backup", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["repeater_id"], name: "index_tunnel_repeaters_on_repeater_id"
    t.index ["tunnel_id", "repeater_id"], name: "index_tunnel_repeaters_on_tunnel_and_repeater", unique: true
  end

  add_foreign_key "custom_repeater_allocations", "repeaters"
  add_foreign_key "dedicated_repeater_allocations", "repeater_ips"
  add_foreign_key "dedicated_repeater_allocations", "repeaters"
  add_foreign_key "repeater_ips", "repeaters"
  add_foreign_key "repeater_sub_regions", "repeater_regions"
  add_foreign_key "repeaters", "repeater_regions"
  add_foreign_key "repeaters", "repeater_sub_regions"
  add_foreign_key "tunnel_repeaters", "repeaters"
end
