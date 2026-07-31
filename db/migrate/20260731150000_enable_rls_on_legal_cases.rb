class EnableRlsOnLegalCases < ActiveRecord::Migration[8.1]
  PUBLIC_TABLES = %w[
    legal_cases process_statuses active_storage_blobs active_storage_attachments
    active_storage_variant_records case_events movement_types process_exams offices
    clients units districts courts deadline_settings deadlines legal_areas process_types
    movement_templates process_phases process_movements process_movement_audits tasks
    user_units users schema_migrations ar_internal_metadata
  ].freeze

  def up
    PUBLIC_TABLES.each do |table_name|
      execute "ALTER TABLE public.#{connection.quote_column_name(table_name)} ENABLE ROW LEVEL SECURITY"
    end

    # Supabase exposes these roles through PostgREST. They are not present in
    # the local PostgreSQL service used by the test suite, so revoke access
    # only when the roles exist.
    execute <<~SQL
      DO $$
      BEGIN
        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
          EXECUTE 'REVOKE ALL ON TABLE public.legal_cases, public.process_statuses,
            public.active_storage_blobs, public.active_storage_attachments,
            public.active_storage_variant_records, public.case_events, public.movement_types,
            public.process_exams, public.offices, public.clients, public.units, public.districts,
            public.courts, public.deadline_settings, public.deadlines, public.legal_areas,
            public.process_types, public.movement_templates, public.process_phases,
            public.process_movements, public.process_movement_audits, public.tasks,
            public.user_units, public.users, public.schema_migrations, public.ar_internal_metadata
            FROM anon';
        END IF;

        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
          EXECUTE 'REVOKE ALL ON TABLE public.legal_cases, public.process_statuses,
            public.active_storage_blobs, public.active_storage_attachments,
            public.active_storage_variant_records, public.case_events, public.movement_types,
            public.process_exams, public.offices, public.clients, public.units, public.districts,
            public.courts, public.deadline_settings, public.deadlines, public.legal_areas,
            public.process_types, public.movement_templates, public.process_phases,
            public.process_movements, public.process_movement_audits, public.tasks,
            public.user_units, public.users, public.schema_migrations, public.ar_internal_metadata
            FROM authenticated';
        END IF;
      END
      $$;
    SQL
  end

  def down
    PUBLIC_TABLES.each do |table_name|
      execute "ALTER TABLE public.#{connection.quote_column_name(table_name)} DISABLE ROW LEVEL SECURITY"
    end
  end
end
