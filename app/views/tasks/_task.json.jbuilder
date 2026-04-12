json.extract! task, :id, :legal_case_id, :title, :description, :status, :priority, :due_date, :responsible_name, :created_at, :updated_at
json.url task_url(task, format: :json)
