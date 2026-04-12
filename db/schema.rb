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

ActiveRecord::Schema[8.1].define(version: 2026_04_12_151131) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "case_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "event_type"
    t.bigint "legal_case_id", null: false
    t.datetime "occurred_at"
    t.string "responsible_name"
    t.datetime "updated_at", null: false
    t.index ["legal_case_id"], name: "index_case_events_on_legal_case_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "address"
    t.date "birth_date"
    t.string "city"
    t.string "cpf_cnpj"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "father_name"
    t.string "full_name"
    t.string "marital_status"
    t.string "mother_name"
    t.text "notes"
    t.string "phone"
    t.string "profession"
    t.string "rg"
    t.string "state"
    t.datetime "updated_at", null: false
    t.string "whatsapp"
  end

  create_table "courts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "district_id"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["district_id"], name: "index_courts_on_district_id"
    t.index ["name"], name: "index_courts_on_name", unique: true
  end

  create_table "deadlines", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "deadline_type"
    t.text "delay_reason"
    t.date "due_date"
    t.bigint "legal_case_id", null: false
    t.string "priority"
    t.string "responsible_name"
    t.date "start_date"
    t.string "status"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["legal_case_id"], name: "index_deadlines_on_legal_case_id"
  end

  create_table "districts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_districts_on_name", unique: true
  end

  create_table "legal_areas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "justice_branch", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["justice_branch", "name"], name: "index_legal_areas_on_justice_branch_and_name", unique: true
  end

  create_table "legal_cases", force: :cascade do |t|
    t.decimal "claim_value"
    t.bigint "client_id", null: false
    t.string "court"
    t.bigint "court_id"
    t.datetime "created_at", null: false
    t.string "district"
    t.bigint "district_id"
    t.date "entry_date"
    t.string "external_number"
    t.string "internal_number"
    t.string "legal_area"
    t.bigint "legal_area_id"
    t.string "main_subject"
    t.string "opposing_party"
    t.string "phase"
    t.string "priority"
    t.string "process_type"
    t.bigint "process_type_id"
    t.date "protocol_date"
    t.string "responsible_name"
    t.string "status"
    t.text "strategic_notes"
    t.string "subarea"
    t.string "support_team"
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_legal_cases_on_client_id"
    t.index ["court_id"], name: "index_legal_cases_on_court_id"
    t.index ["district_id"], name: "index_legal_cases_on_district_id"
    t.index ["legal_area_id"], name: "index_legal_cases_on_legal_area_id"
    t.index ["process_type_id"], name: "index_legal_cases_on_process_type_id"
  end

  create_table "process_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "legal_area_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["legal_area_id", "name"], name: "index_process_types_on_legal_area_id_and_name", unique: true
    t.index ["legal_area_id"], name: "index_process_types_on_legal_area_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.date "due_date"
    t.bigint "legal_case_id", null: false
    t.string "priority"
    t.string "responsible_name"
    t.string "status"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["legal_case_id"], name: "index_tasks_on_legal_case_id"
  end

  add_foreign_key "case_events", "legal_cases"
  add_foreign_key "courts", "districts"
  add_foreign_key "deadlines", "legal_cases"
  add_foreign_key "legal_cases", "clients"
  add_foreign_key "legal_cases", "courts"
  add_foreign_key "legal_cases", "districts"
  add_foreign_key "legal_cases", "legal_areas"
  add_foreign_key "legal_cases", "process_types"
  add_foreign_key "process_types", "legal_areas"
  add_foreign_key "tasks", "legal_cases"
end
