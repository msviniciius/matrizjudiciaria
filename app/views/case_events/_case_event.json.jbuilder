json.extract! case_event, :id, :legal_case_id, :description, :responsible_name, :created_at, :updated_at
json.url case_event_url(case_event, format: :json)
