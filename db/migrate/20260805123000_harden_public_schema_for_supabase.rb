class HardenPublicSchemaForSupabase < ActiveRecord::Migration[8.1]
  TABLES = %w[
    active_storage_attachments
    active_storage_blobs
    active_storage_variant_records
    ar_internal_metadata
    case_events
    clients
    courts
    deadline_settings
    deadlines
    districts
    financial_contracts
    financial_installments
    financial_payments
    legal_areas
    legal_case_ai_analyses
    legal_cases
    legal_publications
    movement_templates
    movement_types
    offices
    process_exams
    process_movement_audits
    process_movements
    process_phases
    process_statuses
    process_types
    receivable_payments
    receivables
    scheduled_job_runs
    schema_migrations
    solid_queue_blocked_executions
    solid_queue_claimed_executions
    solid_queue_failed_executions
    solid_queue_jobs
    solid_queue_pauses
    solid_queue_processes
    solid_queue_ready_executions
    solid_queue_recurring_executions
    solid_queue_recurring_tasks
    solid_queue_scheduled_executions
    solid_queue_semaphores
    tasks
    units
    user_units
    users
  ].freeze

  PUBLIC_API_ROLES = %w[anon authenticated].freeze

  def up
    TABLES.each do |table_name|
      next unless table_exists?(table_name)

      execute %(ALTER TABLE public.#{quote_table_name(table_name)} ENABLE ROW LEVEL SECURITY)
      revoke_public_api_access(table_name)
    end
  end

  def down
    TABLES.each do |table_name|
      next unless table_exists?(table_name)

      execute %(ALTER TABLE public.#{quote_table_name(table_name)} DISABLE ROW LEVEL SECURITY)
    end
  end

  private

  def revoke_public_api_access(table_name)
    PUBLIC_API_ROLES.each do |role_name|
      next unless role_exists?(role_name)

      execute %(REVOKE ALL ON TABLE public.#{quote_table_name(table_name)} FROM #{quote_role_name(role_name)})
    end
  end

  def role_exists?(role_name)
    select_value("SELECT 1 FROM pg_roles WHERE rolname = #{connection.quote(role_name)}").present?
  end

  def quote_role_name(role_name)
    connection.quote_table_name(role_name)
  end
end
