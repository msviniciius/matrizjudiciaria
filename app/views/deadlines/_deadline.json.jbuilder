json.extract! deadline, :id, :legal_case_id, :title, :deadline_type, :start_date, :due_date, :status, :priority, :completed_at, :delay_reason, :responsible_name, :created_at, :updated_at
if deadline.respond_to?(:extended_at)
  json.extended_at deadline.extended_at
end
if deadline.respond_to?(:extended_from_date)
  json.extended_from_date deadline.extended_from_date
end
json.url deadline_url(deadline, format: :json)
