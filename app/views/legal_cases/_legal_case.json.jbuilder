json.extract! legal_case, :id, :internal_number, :external_number, :entry_date, :protocol_date, :process_type, :legal_area, :subarea, :main_subject, :court, :district, :phase, :status, :responsible_name, :support_team, :opposing_party, :claim_value, :priority, :strategic_notes, :client_id, :created_at, :updated_at
json.url legal_case_url(legal_case, format: :json)
