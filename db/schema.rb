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

ActiveRecord::Schema[8.1].define(version: 2026_08_05_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "case_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "entry_kind", default: "andamento", null: false
    t.datetime "event_date"
    t.bigint "legal_case_id", null: false
    t.bigint "movement_type_id"
    t.string "next_action"
    t.string "pje_external_id"
    t.bigint "process_exam_id"
    t.string "responsible_name"
    t.string "source_tribunal"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_case_events_on_created_at"
    t.index ["entry_kind"], name: "index_case_events_on_entry_kind"
    t.index ["event_date"], name: "index_case_events_on_event_date"
    t.index ["legal_case_id"], name: "index_case_events_on_legal_case_id"
    t.index ["movement_type_id"], name: "index_case_events_on_movement_type_id"
    t.index ["pje_external_id"], name: "index_case_events_on_pje_external_id", unique: true, where: "(pje_external_id IS NOT NULL)"
    t.index ["process_exam_id"], name: "index_case_events_on_process_exam_id"
    t.index ["source_tribunal"], name: "index_case_events_on_source_tribunal"
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
    t.bigint "office_id", null: false
    t.string "phone"
    t.string "profession"
    t.string "rg"
    t.string "state"
    t.bigint "unit_id"
    t.datetime "updated_at", null: false
    t.string "whatsapp"
    t.string "zip_code"
    t.index ["cadastro_pendente"], name: "index_clients_on_cadastro_pendente"
    t.index ["office_id"], name: "index_clients_on_office_id"
    t.index ["unit_id"], name: "index_clients_on_unit_id"
    t.index ["zip_code"], name: "index_clients_on_zip_code"
  end

  create_table "courts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "district_id"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["district_id"], name: "index_courts_on_district_id"
    t.index ["name"], name: "index_courts_on_name", unique: true
  end

  create_table "deadline_settings", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.integer "days_to_due", default: 0, null: false
    t.string "deadline_type", null: false
    t.string "default_priority"
    t.text "justification_hint"
    t.string "name", null: false
    t.bigint "office_id", null: false
    t.datetime "updated_at", null: false
    t.index ["office_id", "active"], name: "index_deadline_settings_on_office_id_and_active"
    t.index ["office_id", "deadline_type"], name: "index_deadline_settings_on_office_id_and_deadline_type", unique: true
    t.index ["office_id"], name: "index_deadline_settings_on_office_id"
  end

  create_table "deadlines", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "deadline_type"
    t.text "delay_reason"
    t.date "due_date"
    t.datetime "extended_at"
    t.date "extended_from_date"
    t.bigint "legal_case_id", null: false
    t.string "priority"
    t.string "responsible_name"
    t.date "start_date"
    t.string "status"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["deadline_type"], name: "index_deadlines_on_deadline_type"
    t.index ["due_date"], name: "index_deadlines_on_due_date"
    t.index ["extended_at"], name: "index_deadlines_on_extended_at"
    t.index ["legal_case_id"], name: "index_deadlines_on_legal_case_id"
    t.index ["status"], name: "index_deadlines_on_status"
  end

  create_table "districts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_districts_on_name", unique: true
  end

  create_table "financial_contracts", force: :cascade do |t|
    t.decimal "client_received_amount", precision: 12, scale: 2
    t.datetime "created_at", null: false
    t.decimal "fixed_amount", precision: 12, scale: 2, null: false
    t.boolean "includes_percentage", default: false, null: false
    t.integer "installment_count", default: 1, null: false
    t.bigint "legal_case_id", null: false
    t.bigint "office_id", null: false
    t.decimal "percentage", precision: 5, scale: 2
    t.string "percentage_basis"
    t.decimal "total_amount", precision: 12, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["legal_case_id"], name: "index_financial_contracts_on_legal_case_id", unique: true
    t.index ["office_id"], name: "index_financial_contracts_on_office_id"
    t.check_constraint "client_received_amount IS NULL OR client_received_amount >= 0::numeric", name: "financial_contracts_client_received_amount_nonnegative"
    t.check_constraint "fixed_amount > 0::numeric", name: "financial_contracts_fixed_amount_positive"
    t.check_constraint "includes_percentage AND percentage > 0::numeric AND percentage <= 100::numeric AND (percentage_basis::text = ANY (ARRAY['claim_value'::character varying, 'client_received'::character varying]::text[])) OR NOT includes_percentage AND percentage IS NULL AND percentage_basis IS NULL", name: "financial_contracts_percentage_configuration"
    t.check_constraint "installment_count >= 1 AND installment_count <= 12", name: "financial_contracts_installment_count_range"
    t.check_constraint "total_amount > 0::numeric", name: "financial_contracts_total_amount_positive"
  end

  create_table "financial_installments", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.date "due_date", null: false
    t.bigint "financial_contract_id", null: false
    t.integer "number", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["due_date"], name: "index_financial_installments_on_due_date"
    t.index ["financial_contract_id", "number"], name: "index_financial_installments_on_contract_and_number", unique: true
    t.index ["financial_contract_id"], name: "index_financial_installments_on_financial_contract_id"
    t.index ["status"], name: "index_financial_installments_on_status"
    t.check_constraint "amount > 0::numeric", name: "financial_installments_amount_positive"
    t.check_constraint "number >= 1 AND number <= 12", name: "financial_installments_number_range"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'paid'::character varying]::text[])", name: "financial_installments_status_allowed"
  end

  create_table "financial_payments", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.bigint "financial_installment_id", null: false
    t.datetime "paid_at", null: false
    t.string "payment_method", null: false
    t.bigint "recorded_by_id", null: false
    t.datetime "updated_at", null: false
    t.index ["financial_installment_id"], name: "index_financial_payments_on_financial_installment_id", unique: true
    t.index ["recorded_by_id"], name: "index_financial_payments_on_recorded_by_id"
    t.check_constraint "amount > 0::numeric", name: "financial_payments_amount_positive"
    t.check_constraint "payment_method::text = ANY (ARRAY['pix'::character varying, 'cash'::character varying, 'credit_card'::character varying, 'debit_card'::character varying]::text[])", name: "financial_payments_method_allowed"
  end

  create_table "legal_areas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "justice_branch", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["justice_branch", "name"], name: "index_legal_areas_on_justice_branch_and_name", unique: true
  end

  create_table "legal_case_ai_analyses", force: :cascade do |t|
    t.string "confidence", default: "low", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.jsonb "deterministic_snapshot", default: {}, null: false
    t.bigint "legal_case_id", null: false
    t.string "model", null: false
    t.text "notes"
    t.string "provider", null: false
    t.jsonb "raw_response", default: {}, null: false
    t.jsonb "risks", default: [], null: false
    t.text "suggested_action", null: false
    t.text "summary", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_legal_case_ai_analyses_on_created_by_id"
    t.index ["legal_case_id", "created_at"], name: "index_legal_case_ai_analyses_on_legal_case_id_and_created_at"
    t.index ["legal_case_id"], name: "index_legal_case_ai_analyses_on_legal_case_id"
    t.index ["provider", "model"], name: "index_legal_case_ai_analyses_on_provider_and_model"
  end

  create_table "legal_cases", force: :cascade do |t|
    t.decimal "claim_value"
    t.bigint "client_id", null: false
    t.bigint "court_id"
    t.datetime "created_at", null: false
    t.bigint "district_id"
    t.date "entry_date"
    t.string "external_number"
    t.string "internal_number"
    t.text "last_movement"
    t.datetime "last_movement_at"
    t.datetime "last_synced_at"
    t.datetime "last_viewed_events_at"
    t.bigint "legal_area_id"
    t.string "main_subject"
    t.string "next_action"
    t.date "next_deadline_on"
    t.text "observacao_geral_pericia"
    t.bigint "office_id", null: false
    t.string "opposing_party"
    t.string "outcome", default: "undefined", null: false
    t.datetime "outcome_confirmed_at"
    t.bigint "outcome_confirmed_by_id"
    t.date "outcome_date"
    t.text "outcome_notes"
    t.string "phase"
    t.string "pje_case_id"
    t.string "priority"
    t.bigint "process_type_id"
    t.date "protocol_date"
    t.string "responsible_name"
    t.string "status"
    t.text "strategic_notes"
    t.string "subarea"
    t.string "support_team"
    t.boolean "tem_pericia", default: false, null: false
    t.bigint "unit_id"
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_legal_cases_on_client_id"
    t.index ["court_id"], name: "index_legal_cases_on_court_id"
    t.index ["district_id"], name: "index_legal_cases_on_district_id"
    t.index ["last_synced_at"], name: "index_legal_cases_on_last_synced_at"
    t.index ["legal_area_id"], name: "index_legal_cases_on_legal_area_id"
    t.index ["office_id"], name: "index_legal_cases_on_office_id"
    t.index ["outcome"], name: "index_legal_cases_on_outcome"
    t.index ["outcome_confirmed_by_id"], name: "index_legal_cases_on_outcome_confirmed_by_id"
    t.index ["pje_case_id"], name: "index_legal_cases_on_pje_case_id"
    t.index ["process_type_id"], name: "index_legal_cases_on_process_type_id"
    t.index ["unit_id"], name: "index_legal_cases_on_unit_id"
  end

  create_table "legal_publications", force: :cascade do |t|
    t.text "content", null: false
    t.string "court_name"
    t.datetime "created_at", null: false
    t.string "event_name", null: false
    t.string "external_id", null: false
    t.string "journal_name"
    t.bigint "legal_case_id"
    t.bigint "office_id", null: false
    t.string "process_number"
    t.datetime "published_at"
    t.jsonb "raw_payload", default: {}, null: false
    t.datetime "read_at"
    t.string "source", default: "escavador", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["legal_case_id"], name: "index_legal_publications_on_legal_case_id"
    t.index ["office_id", "legal_case_id"], name: "index_legal_publications_on_office_id_and_legal_case_id"
    t.index ["office_id", "read_at"], name: "index_legal_publications_on_office_id_and_read_at"
    t.index ["office_id"], name: "index_legal_publications_on_office_id"
    t.index ["process_number"], name: "index_legal_publications_on_process_number"
    t.index ["source", "external_id"], name: "index_legal_publications_on_source_and_external_id", unique: true
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

  create_table "offices", force: :cascade do |t|
    t.string "address"
    t.string "city"
    t.string "cnpj"
    t.datetime "created_at", null: false
    t.integer "deadline_alert_days", default: 7, null: false
    t.string "default_phase", default: "atendimento_inicial", null: false
    t.string "default_priority", default: "medium", null: false
    t.string "default_status", default: "em_analise", null: false
    t.string "email"
    t.string "enabled_tribunals", default: [], null: false, array: true
    t.string "legal_name"
    t.string "name", null: false
    t.string "oab_registration"
    t.string "oab_state", limit: 2
    t.string "phone"
    t.string "primary_color", default: "#112f4e", null: false
    t.string "secondary_color", default: "#b08a45", null: false
    t.string "slug", null: false
    t.string "state"
    t.integer "task_alert_days", default: 7, null: false
    t.datetime "updated_at", null: false
    t.string "zip_code"
    t.index ["cnpj"], name: "index_offices_on_cnpj"
    t.index ["email"], name: "index_offices_on_email"
    t.index ["enabled_tribunals"], name: "index_offices_on_enabled_tribunals", using: :gin
    t.index ["slug"], name: "index_offices_on_slug", unique: true
    t.index ["zip_code"], name: "index_offices_on_zip_code"
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

  create_table "receivable_payments", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.date "paid_at", null: false
    t.string "payment_method"
    t.bigint "receivable_id", null: false
    t.bigint "recorded_by_id"
    t.datetime "updated_at", null: false
    t.index ["receivable_id"], name: "index_receivable_payments_on_receivable_id"
    t.index ["recorded_by_id"], name: "index_receivable_payments_on_recorded_by_id"
  end

  create_table "receivables", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.decimal "amount_paid", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "canceled_at"
    t.bigint "canceled_by_id"
    t.bigint "client_id"
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.date "due_date"
    t.bigint "legal_case_id"
    t.boolean "migrated_to_financial_contract", default: false, null: false
    t.text "notes"
    t.bigint "office_id", null: false
    t.date "paid_at"
    t.string "payment_method"
    t.datetime "payment_recorded_at"
    t.bigint "payment_recorded_by_id"
    t.string "status", default: "pending", null: false
    t.string "trigger", default: "manual", null: false
    t.datetime "triggered_at"
    t.bigint "unit_id"
    t.datetime "updated_at", null: false
    t.index ["canceled_by_id"], name: "index_receivables_on_canceled_by_id"
    t.index ["client_id"], name: "index_receivables_on_client_id"
    t.index ["due_date"], name: "index_receivables_on_due_date"
    t.index ["legal_case_id"], name: "index_receivables_on_legal_case_id"
    t.index ["migrated_to_financial_contract"], name: "index_receivables_on_migrated_to_financial_contract"
    t.index ["office_id"], name: "index_receivables_on_office_id"
    t.index ["payment_recorded_by_id"], name: "index_receivables_on_payment_recorded_by_id"
    t.index ["status"], name: "index_receivables_on_status"
    t.index ["unit_id"], name: "index_receivables_on_unit_id"
  end

  create_table "scheduled_job_runs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_ms", default: 0, null: false
    t.text "error_message"
    t.datetime "finished_at", null: false
    t.string "job_name", null: false
    t.jsonb "result", default: {}, null: false
    t.datetime "started_at", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["job_name", "started_at"], name: "index_scheduled_job_runs_on_job_name_and_started_at"
    t.index ["status", "started_at"], name: "index_scheduled_job_runs_on_status_and_started_at"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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
    t.index ["due_date"], name: "index_tasks_on_due_date"
    t.index ["legal_case_id"], name: "index_tasks_on_legal_case_id"
    t.index ["responsible_name"], name: "index_tasks_on_responsible_name"
    t.index ["status"], name: "index_tasks_on_status"
  end

  create_table "units", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "address"
    t.string "city"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.bigint "office_id", null: false
    t.string "phone"
    t.string "responsible_name"
    t.string "slug", null: false
    t.string "state"
    t.datetime "updated_at", null: false
    t.string "zip_code"
    t.index ["email"], name: "index_units_on_email"
    t.index ["office_id", "name"], name: "index_units_on_office_id_and_name", unique: true
    t.index ["office_id", "slug"], name: "index_units_on_office_id_and_slug", unique: true
    t.index ["office_id"], name: "index_units_on_office_id"
  end

  create_table "user_units", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "unit_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["unit_id"], name: "index_user_units_on_unit_id"
    t.index ["user_id", "unit_id"], name: "index_user_units_on_user_id_and_unit_id", unique: true
    t.index ["user_id"], name: "index_user_units_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "last_sign_in_at"
    t.boolean "matrix_access", default: true, null: false
    t.string "name", null: false
    t.bigint "office_id", null: false
    t.string "password_digest", null: false
    t.string "password_salt", null: false
    t.string "role", default: "attendant", null: false
    t.datetime "updated_at", null: false
    t.string "whatsapp_number"
    t.datetime "whatsapp_opted_in_at"
    t.index ["office_id", "email"], name: "index_users_on_office_id_and_email", unique: true
    t.index ["office_id", "role", "active", "whatsapp_number"], name: "index_users_on_office_role_active_whatsapp"
    t.index ["office_id"], name: "index_users_on_office_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "case_events", "legal_cases"
  add_foreign_key "case_events", "movement_types"
  add_foreign_key "case_events", "process_exams"
  add_foreign_key "clients", "offices"
  add_foreign_key "clients", "units"
  add_foreign_key "courts", "districts"
  add_foreign_key "deadline_settings", "offices"
  add_foreign_key "deadlines", "legal_cases"
  add_foreign_key "financial_contracts", "legal_cases"
  add_foreign_key "financial_contracts", "offices"
  add_foreign_key "financial_installments", "financial_contracts"
  add_foreign_key "financial_payments", "financial_installments"
  add_foreign_key "financial_payments", "users", column: "recorded_by_id"
  add_foreign_key "legal_case_ai_analyses", "legal_cases"
  add_foreign_key "legal_case_ai_analyses", "users", column: "created_by_id"
  add_foreign_key "legal_cases", "clients"
  add_foreign_key "legal_cases", "courts"
  add_foreign_key "legal_cases", "districts"
  add_foreign_key "legal_cases", "legal_areas"
  add_foreign_key "legal_cases", "offices"
  add_foreign_key "legal_cases", "process_types"
  add_foreign_key "legal_cases", "units"
  add_foreign_key "legal_cases", "users", column: "outcome_confirmed_by_id"
  add_foreign_key "legal_publications", "legal_cases"
  add_foreign_key "legal_publications", "offices"
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
  add_foreign_key "receivable_payments", "receivables"
  add_foreign_key "receivable_payments", "users", column: "recorded_by_id"
  add_foreign_key "receivables", "clients"
  add_foreign_key "receivables", "legal_cases"
  add_foreign_key "receivables", "offices"
  add_foreign_key "receivables", "units"
  add_foreign_key "receivables", "users", column: "canceled_by_id"
  add_foreign_key "receivables", "users", column: "payment_recorded_by_id"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "tasks", "legal_cases"
  add_foreign_key "units", "offices"
  add_foreign_key "user_units", "units"
  add_foreign_key "user_units", "users"
  add_foreign_key "users", "offices"
end
