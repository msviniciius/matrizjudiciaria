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

ActiveRecord::Schema[8.1].define(version: 2026_04_19_170000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "case_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "entry_kind", default: "andamento", null: false
    t.string "event_type"
    t.bigint "legal_case_id", null: false
    t.bigint "movement_type_id"
    t.string "next_action"
    t.datetime "occurred_at"
    t.bigint "process_exam_id"
    t.string "responsible_name"
    t.datetime "updated_at", null: false
    t.index ["entry_kind"], name: "index_case_events_on_entry_kind"
    t.index ["legal_case_id"], name: "index_case_events_on_legal_case_id"
    t.index ["movement_type_id"], name: "index_case_events_on_movement_type_id"
    t.index ["occurred_at"], name: "index_case_events_on_occurred_at"
    t.index ["process_exam_id"], name: "index_case_events_on_process_exam_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "address"
    t.date "birth_date"
    t.boolean "cadastro_pendente", default: false, null: false
    t.string "city"
    t.string "cpf_cnpj"
    t.datetime "created_at", null: false
    t.text "dados_gov"
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
    t.index ["cadastro_pendente"], name: "index_clients_on_cadastro_pendente"
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
    t.text "last_movement"
    t.datetime "last_movement_at"
    t.string "legal_area"
    t.bigint "legal_area_id"
    t.string "main_subject"
    t.string "next_action"
    t.date "next_deadline_on"
    t.text "observacao_geral_pericia"
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
    t.boolean "tem_pericia", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_legal_cases_on_client_id"
    t.index ["court_id"], name: "index_legal_cases_on_court_id"
    t.index ["district_id"], name: "index_legal_cases_on_district_id"
    t.index ["legal_area_id"], name: "index_legal_cases_on_legal_area_id"
    t.index ["process_type_id"], name: "index_legal_cases_on_process_type_id"
  end

  create_table "movement_templates", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.boolean "creates_deadline", default: false, null: false
    t.boolean "creates_task", default: false, null: false
    t.string "deadline_template_name"
    t.string "impact_default", null: false
    t.bigint "movement_type_id", null: false
    t.string "name", null: false
    t.string "nature_default", null: false
    t.bigint "next_phase_id"
    t.integer "order", default: 0, null: false
    t.bigint "phase_id", null: false
    t.boolean "requires_exam_id", default: false, null: false
    t.text "short_description"
    t.string "task_template_name"
    t.datetime "updated_at", null: false
    t.boolean "updates_phase", default: false, null: false
    t.index ["code"], name: "index_movement_templates_on_code", unique: true
    t.index ["movement_type_id", "active"], name: "index_movement_templates_on_movement_type_id_and_active"
    t.index ["movement_type_id"], name: "index_movement_templates_on_movement_type_id"
    t.index ["next_phase_id"], name: "index_movement_templates_on_next_phase_id"
    t.index ["phase_id", "active", "order"], name: "index_movement_templates_on_phase_id_and_active_and_order"
    t.index ["phase_id"], name: "index_movement_templates_on_phase_id"
  end

  create_table "movement_types", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_movement_types_on_code", unique: true
    t.index ["name"], name: "index_movement_types_on_name", unique: true
  end

  create_table "process_exams", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_user_id"
    t.string "exam_nature", null: false
    t.string "exam_scope", null: false
    t.string "expert_name"
    t.bigint "legal_case_id", null: false
    t.string "location"
    t.text "notes"
    t.datetime "scheduled_at"
    t.string "status", default: "nao_designada", null: false
    t.datetime "updated_at", null: false
    t.index ["legal_case_id", "active"], name: "index_process_exams_on_legal_case_id_and_active"
    t.index ["legal_case_id"], name: "index_process_exams_on_legal_case_id"
    t.index ["scheduled_at"], name: "index_process_exams_on_scheduled_at"
    t.index ["status"], name: "index_process_exams_on_status"
  end

  create_table "process_movement_audits", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "changed_by_user_id"
    t.jsonb "changed_fields", default: {}, null: false
    t.datetime "created_at", null: false
    t.text "justification"
    t.bigint "process_movement_id", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_process_movement_audits_on_action"
    t.index ["changed_by_user_id"], name: "index_process_movement_audits_on_changed_by_user_id"
    t.index ["created_at"], name: "index_process_movement_audits_on_created_at"
    t.index ["process_movement_id"], name: "index_process_movement_audits_on_process_movement_id"
  end

  create_table "process_movements", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "administrative_situation"
    t.text "complementary_description"
    t.datetime "created_at", null: false
    t.bigint "created_by_user_id"
    t.boolean "creates_deadline", default: false, null: false
    t.boolean "creates_task", default: false, null: false
    t.string "display_title", null: false
    t.datetime "event_date", null: false
    t.bigint "exam_id"
    t.boolean "exception_authorized", default: false, null: false
    t.string "impact", null: false
    t.boolean "manual_override", default: false, null: false
    t.bigint "movement_template_id"
    t.bigint "movement_type_id", null: false
    t.string "nature", null: false
    t.bigint "next_phase_id"
    t.string "origin", null: false
    t.bigint "override_by_user_id"
    t.text "override_reason"
    t.bigint "phase_id", null: false
    t.bigint "process_id", null: false
    t.datetime "updated_at", null: false
    t.boolean "updates_phase", default: false, null: false
    t.index ["active", "event_date"], name: "index_process_movements_on_active_and_event_date"
    t.index ["administrative_situation"], name: "index_process_movements_on_administrative_situation"
    t.index ["exam_id"], name: "index_process_movements_on_exam_id"
    t.index ["manual_override"], name: "index_process_movements_on_manual_override"
    t.index ["movement_template_id"], name: "index_process_movements_on_movement_template_id"
    t.index ["movement_type_id", "event_date"], name: "index_process_movements_on_movement_type_id_and_event_date"
    t.index ["movement_type_id"], name: "index_process_movements_on_movement_type_id"
    t.index ["next_phase_id"], name: "index_process_movements_on_next_phase_id"
    t.index ["override_by_user_id"], name: "index_process_movements_on_override_by_user_id"
    t.index ["phase_id"], name: "index_process_movements_on_phase_id"
    t.index ["process_id", "event_date"], name: "index_process_movements_on_process_id_and_event_date"
    t.index ["process_id"], name: "index_process_movements_on_process_id"
  end

  create_table "process_phases", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "order", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["active", "order"], name: "index_process_phases_on_active_and_order"
    t.index ["code"], name: "index_process_phases_on_code", unique: true
  end

  create_table "process_statuses", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "order", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["active", "order"], name: "index_process_statuses_on_active_and_order"
    t.index ["code"], name: "index_process_statuses_on_code", unique: true
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
  add_foreign_key "case_events", "movement_types"
  add_foreign_key "case_events", "process_exams"
  add_foreign_key "courts", "districts"
  add_foreign_key "deadlines", "legal_cases"
  add_foreign_key "legal_cases", "clients"
  add_foreign_key "legal_cases", "courts"
  add_foreign_key "legal_cases", "districts"
  add_foreign_key "legal_cases", "legal_areas"
  add_foreign_key "legal_cases", "process_types"
  add_foreign_key "movement_templates", "movement_types"
  add_foreign_key "movement_templates", "process_phases", column: "next_phase_id"
  add_foreign_key "movement_templates", "process_phases", column: "phase_id"
  add_foreign_key "process_exams", "legal_cases"
  add_foreign_key "process_movement_audits", "process_movements"
  add_foreign_key "process_movements", "legal_cases", column: "process_id"
  add_foreign_key "process_movements", "movement_templates"
  add_foreign_key "process_movements", "movement_types"
  add_foreign_key "process_movements", "process_exams", column: "exam_id"
  add_foreign_key "process_movements", "process_phases", column: "next_phase_id"
  add_foreign_key "process_movements", "process_phases", column: "phase_id"
  add_foreign_key "process_types", "legal_areas"
  add_foreign_key "tasks", "legal_cases"
end
