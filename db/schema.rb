# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140129095429) do

  create_table "domains", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ip_addresses", force: true do |t|
    t.integer  "region_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "address",       limit: 8,          default: 0
    t.text     "settings",      limit: 2147483647
    t.boolean  "has_full_scan",                    default: false
    t.string   "hostname"
  end

  add_index "ip_addresses", ["address"], name: "index_ip_addresses_on_address", unique: true, using: :btree
  add_index "ip_addresses", ["region_id"], name: "index_ip_addresses_on_region_id", using: :btree

  create_table "ports", force: true do |t|
    t.integer  "number"
    t.integer  "ip_address_id"
    t.integer  "scan_id"
    t.string   "product"
    t.string   "version"
    t.text     "extra"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "notes"
    t.boolean  "done"
    t.text     "settings",      limit: 2147483647
    t.boolean  "ssl"
    t.boolean  "screenshotted",                    default: false
    t.text     "nikto_results"
    t.string   "final_url"
  end

  add_index "ports", ["done"], name: "index_ports_on_done", using: :btree
  add_index "ports", ["ip_address_id"], name: "index_ports_on_ip_address_id", using: :btree
  add_index "ports", ["number"], name: "index_ports_on_number", using: :btree
  add_index "ports", ["screenshotted"], name: "index_ports_on_screenshotted", using: :btree
  add_index "ports", ["ssl"], name: "index_ports_on_ssl", using: :btree

  create_table "regions", force: true do |t|
    t.string   "name"
    t.float    "utc_start_test"
    t.float    "utc_end_test"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "scans", force: true do |t|
    t.integer  "ip_address_id"
    t.text     "results",       limit: 2147483647
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "options"
    t.boolean  "processed",                        default: false, null: false
    t.boolean  "timed_out"
  end

  add_index "scans", ["ip_address_id"], name: "index_scans_on_ip_address_id", using: :btree

  create_table "screenshots", force: true do |t|
    t.string   "url"
    t.binary   "data",                limit: 16777215
    t.integer  "screenshotable_id"
    t.string   "screenshotable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "taggings", force: true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       limit: 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id", "taggable_id"], name: "index_taggings_on_tag_id_and_taggable_id", using: :btree
  add_index "taggings", ["tag_id"], name: "index_taggings_on_tag_id", using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree

  create_table "tags", force: true do |t|
    t.string "name"
  end

end
