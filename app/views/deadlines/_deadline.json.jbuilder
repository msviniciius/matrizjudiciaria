json.extract! deadline, :id, :legal_case_id, :title, :deadline_type, :start_date, :due_date, :status, :priority, :completed_at, :delay_reason, :responsible_name, :created_at, :updated_at
json.url deadline_url(deadline, format: :json)
