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

ActiveRecord::Schema[7.0].define(version: 2025_06_10_210845) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "dev_feature_flags", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.boolean "enabled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_dev_feature_flags_on_name", unique: true
  end

  create_table "dev_processes", force: :cascade do |t|
    t.string "process_type"
    t.string "content"
    t.datetime "process_actives_at"
    t.string "priority"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fifty_churches", force: :cascade do |t|
    t.string "parroquia"
    t.bigint "fifty_town_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fifty_town_id"], name: "index_fifty_churches_on_fifty_town_id"
  end

  create_table "fifty_cities", force: :cascade do |t|
    t.string "ciudad"
    t.bigint "fifty_location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fifty_location_id"], name: "index_fifty_cities_on_fifty_location_id"
  end

  create_table "fifty_locations", force: :cascade do |t|
    t.string "iso_31662"
    t.string "estado"
    t.string "capital"
    t.integer "id_estado"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fifty_stadia", force: :cascade do |t|
    t.string "name"
    t.integer "fifty_location", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fifty_towns", force: :cascade do |t|
    t.string "municipio"
    t.string "capital"
    t.bigint "fifty_location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fifty_location_id"], name: "index_fifty_towns_on_fifty_location_id"
  end

  create_table "rifamax_raffles", force: :cascade do |t|
    t.string "title"
    t.date "init_date"
    t.date "expired_date"
    t.jsonb "prizes", default: [], array: true
    t.float "price"
    t.integer "numbers"
    t.string "currency"
    t.string "lotery"
    t.integer "sell_status"
    t.integer "admin_status"
    t.jsonb "payment_info"
    t.jsonb "security"
    t.string "uniq_identifier_serial"
    t.bigint "user_id", null: false
    t.bigint "seller_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "buy_amount"
    t.text "details"
    t.string "buy_currency"
    t.index ["seller_id"], name: "index_rifamax_raffles_on_seller_id"
    t.index ["user_id"], name: "index_rifamax_raffles_on_user_id"
  end

  create_table "rifamax_tickets", force: :cascade do |t|
    t.string "wildcard"
    t.integer "number"
    t.integer "number_position"
    t.string "uniq_identifier_serial"
    t.boolean "is_sold"
    t.boolean "is_winner"
    t.bigint "raffle_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["raffle_id"], name: "index_rifamax_tickets_on_raffle_id"
  end

  create_table "shared_application_modules", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shared_currencies", force: :cascade do |t|
    t.string "currency"
    t.string "label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shared_exchanges", force: :cascade do |t|
    t.boolean "automatic"
    t.float "value_bs"
    t.float "value_cop"
    t.string "mainstream_money"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shared_lotteries", force: :cascade do |t|
    t.string "name"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shared_products", force: :cascade do |t|
    t.string "name"
    t.string "image"
    t.string "color"
    t.string "to"
    t.string "roles", default: [], array: true
    t.string "devices", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shared_sprites", force: :cascade do |t|
    t.string "asset"
    t.integer "each_width"
    t.integer "each_height"
    t.integer "width"
    t.integer "height"
    t.string "identifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shared_structures", force: :cascade do |t|
    t.string "name"
    t.string "token", default: "rm_live_10195371-2f1a-430a-bf34-c98b2fe0da1c"
    t.string "access_to", default: [], array: true
    t.bigint "shared_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "promotional"
    t.string "known_as"
    t.string "url_base"
    t.string "user_path"
    t.index ["shared_user_id"], name: "index_shared_structures_on_shared_user_id"
  end

  create_table "shared_transactions", force: :cascade do |t|
    t.string "transaction_type"
    t.bigint "shared_wallet_id", null: false
    t.float "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shared_wallet_id"], name: "index_shared_transactions_on_shared_wallet_id"
  end

  create_table "shared_users", force: :cascade do |t|
    t.string "avatar"
    t.string "name"
    t.string "role"
    t.string "dni"
    t.string "email"
    t.string "phone"
    t.string "password_digest"
    t.string "slug"
    t.boolean "is_active"
    t.integer "rifero_ids", default: [], array: true
    t.integer "module_assigned", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_integration", default: false
    t.boolean "is_first_entry", default: false
    t.boolean "welcoming", default: true
    t.integer "structure_id"
    t.integer "integrator_id"
    t.string "integrator_type"
  end

  create_table "shared_wallets", force: :cascade do |t|
    t.string "token", default: "8c456bb7-1ac8-4a91-b2e1-2a7072917b24"
    t.float "found", default: 0.0
    t.float "debt", default: 0.0
    t.float "debt_limit", default: 20.0
    t.bigint "shared_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shared_user_id"], name: "index_shared_wallets_on_shared_user_id"
  end

  create_table "social_badges", force: :cascade do |t|
    t.string "title"
    t.string "color"
    t.string "icon"
    t.bigint "social_influencer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["social_influencer_id"], name: "index_social_badges_on_social_influencer_id"
  end

  create_table "social_clients", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "country"
    t.string "province"
    t.string "zip_code"
    t.string "address"
  end

  create_table "social_fees", force: :cascade do |t|
    t.float "admin_profit_fee"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "social_influencers", force: :cascade do |t|
    t.string "content_code"
    t.bigint "shared_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shared_user_id"], name: "index_social_influencers_on_shared_user_id"
  end

  create_table "social_lotteries", force: :cascade do |t|
    t.string "name"
    t.float "profit_fee"
    t.string "key_name"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "shared_user_id", null: false
    t.index ["shared_user_id"], name: "index_social_lotteries_on_shared_user_id"
  end

  create_table "social_networks", force: :cascade do |t|
    t.string "name"
    t.string "username"
    t.string "url"
    t.bigint "social_influencer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["social_influencer_id"], name: "index_social_networks_on_social_influencer_id"
  end

  create_table "social_orders", force: :cascade do |t|
    t.float "amount"
    t.string "money"
    t.datetime "ordered_at"
    t.integer "products"
    t.string "serial"
    t.string "status"
    t.bigint "social_client_id", null: false
    t.bigint "social_raffle_id", null: false
    t.bigint "shared_exchange_id", null: false
    t.bigint "social_payment_method_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shared_exchange_id"], name: "index_social_orders_on_shared_exchange_id"
    t.index ["social_client_id"], name: "index_social_orders_on_social_client_id"
    t.index ["social_payment_method_id"], name: "index_social_orders_on_social_payment_method_id"
    t.index ["social_raffle_id"], name: "index_social_orders_on_social_raffle_id"
  end

  create_table "social_payment_methods", force: :cascade do |t|
    t.string "payment"
    t.jsonb "details"
    t.bigint "social_client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "amount"
    t.string "currency"
    t.bigint "social_influencer_id"
    t.bigint "social_raffle_id"
    t.string "status"
    t.bigint "shared_exchange_id"
    t.integer "quantity_requested"
    t.boolean "email_send", default: false
    t.boolean "whatsapp_send", default: false
    t.index ["shared_exchange_id"], name: "index_social_payment_methods_on_shared_exchange_id"
    t.index ["social_client_id"], name: "index_social_payment_methods_on_social_client_id"
    t.index ["social_influencer_id"], name: "index_social_payment_methods_on_social_influencer_id"
    t.index ["social_raffle_id"], name: "index_social_payment_methods_on_social_raffle_id"
  end

  create_table "social_payment_options", force: :cascade do |t|
    t.string "name"
    t.jsonb "details"
    t.string "country"
    t.bigint "social_influencer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["social_influencer_id"], name: "index_social_payment_options_on_social_influencer_id"
  end

  create_table "social_raffles", force: :cascade do |t|
    t.string "ad"
    t.jsonb "combos"
    t.string "raffle_type"
    t.boolean "has_winners"
    t.datetime "init_date"
    t.datetime "expired_date"
    t.float "price_unit"
    t.string "draw_type"
    t.integer "tickets_count"
    t.string "status"
    t.string "title"
    t.jsonb "winners"
    t.jsonb "prizes"
    t.string "money"
    t.integer "limit"
    t.bigint "social_influencer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "social_fee_id"
    t.bigint "social_lottery_id"
    t.index ["social_fee_id"], name: "index_social_raffles_on_social_fee_id"
    t.index ["social_influencer_id"], name: "index_social_raffles_on_social_influencer_id"
    t.index ["social_lottery_id"], name: "index_social_raffles_on_social_lottery_id"
  end

  create_table "social_tickets", force: :cascade do |t|
    t.string "money"
    t.integer "position"
    t.float "price"
    t.string "serial"
    t.string "status"
    t.bigint "social_raffle_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["social_raffle_id"], name: "index_social_tickets_on_social_raffle_id"
  end

  create_table "x100_clients", force: :cascade do |t|
    t.string "name"
    t.string "dni"
    t.string "phone"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "integrator_id"
    t.string "integrator_type"
    t.boolean "pv", default: false
    t.string "username"
  end

  create_table "x100_orders", force: :cascade do |t|
    t.integer "products", default: [], array: true
    t.float "amount"
    t.string "serial"
    t.string "money"
    t.datetime "ordered_at"
    t.bigint "shared_user_id", null: false
    t.bigint "x100_client_id", null: false
    t.bigint "x100_raffle_id", null: false
    t.bigint "shared_exchange_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "integrator_player_id"
    t.string "integrator"
    t.string "status", default: "active"
    t.jsonb "logs", default: [], array: true
    t.index ["shared_exchange_id"], name: "index_x100_orders_on_shared_exchange_id"
    t.index ["shared_user_id"], name: "index_x100_orders_on_shared_user_id"
    t.index ["x100_client_id"], name: "index_x100_orders_on_x100_client_id"
    t.index ["x100_raffle_id"], name: "index_x100_orders_on_x100_raffle_id"
  end

  create_table "x100_raffles", force: :cascade do |t|
    t.string "ad"
    t.string "title"
    t.string "draw_type"
    t.string "status"
    t.integer "limit"
    t.string "money"
    t.string "raffle_type"
    t.float "price_unit"
    t.integer "tickets_count"
    t.integer "numbers"
    t.string "lotery"
    t.datetime "expired_date"
    t.datetime "init_date"
    t.jsonb "prizes"
    t.jsonb "winners"
    t.boolean "has_winners"
    t.integer "automatic_taquillas_ids", default: [], array: true
    t.integer "shared_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "combos"
  end

  create_table "x100_stats", force: :cascade do |t|
    t.integer "tickets_sold"
    t.float "profit"
    t.bigint "x100_raffle_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["x100_raffle_id"], name: "index_x100_stats_on_x100_raffle_id"
  end

  create_table "x100_tickets", force: :cascade do |t|
    t.integer "position"
    t.string "serial", default: "8211942d-2e22-48b5-ad9d-bbb38523f0c4"
    t.float "price"
    t.string "money"
    t.string "status", default: "available"
    t.bigint "x100_raffle_id", null: false
    t.bigint "x100_client_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "apart_ends"
    t.integer "aparted_by"
    t.index ["x100_client_id"], name: "index_x100_tickets_on_x100_client_id"
    t.index ["x100_raffle_id"], name: "index_x100_tickets_on_x100_raffle_id"
  end

  add_foreign_key "fifty_churches", "fifty_towns"
  add_foreign_key "fifty_cities", "fifty_locations"
  add_foreign_key "fifty_towns", "fifty_locations"
  add_foreign_key "rifamax_raffles", "shared_users", column: "seller_id"
  add_foreign_key "rifamax_raffles", "shared_users", column: "user_id"
  add_foreign_key "rifamax_tickets", "rifamax_raffles", column: "raffle_id"
  add_foreign_key "shared_structures", "shared_users"
  add_foreign_key "shared_transactions", "shared_wallets"
  add_foreign_key "shared_wallets", "shared_users"
  add_foreign_key "social_badges", "social_influencers"
  add_foreign_key "social_influencers", "shared_users"
  add_foreign_key "social_lotteries", "shared_users"
  add_foreign_key "social_networks", "social_influencers"
  add_foreign_key "social_orders", "shared_exchanges"
  add_foreign_key "social_orders", "social_clients"
  add_foreign_key "social_orders", "social_payment_methods"
  add_foreign_key "social_orders", "social_raffles"
  add_foreign_key "social_payment_methods", "shared_exchanges"
  add_foreign_key "social_payment_methods", "social_clients"
  add_foreign_key "social_payment_methods", "social_influencers"
  add_foreign_key "social_payment_methods", "social_raffles"
  add_foreign_key "social_payment_options", "social_influencers"
  add_foreign_key "social_raffles", "social_fees"
  add_foreign_key "social_raffles", "social_influencers"
  add_foreign_key "social_raffles", "social_lotteries"
  add_foreign_key "social_tickets", "social_raffles"
  add_foreign_key "x100_orders", "shared_exchanges"
  add_foreign_key "x100_orders", "shared_users"
  add_foreign_key "x100_orders", "x100_clients"
  add_foreign_key "x100_orders", "x100_raffles"
  add_foreign_key "x100_stats", "x100_raffles"
  add_foreign_key "x100_tickets", "x100_clients"
  add_foreign_key "x100_tickets", "x100_raffles"
end
