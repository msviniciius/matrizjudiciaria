json.task do
  json.id @task.id
  json.title @task.title
  json.description @task.description
  json.status_label enum_label(Task, :status, @task.status)
  json.priority_label(@task.priority.present? ? enum_label(Task, :priority, @task.priority) : "-")
  json.due_date_label(@task.due_date.present? ? l(@task.due_date, format: :short) : "-")
  json.responsible_name(@task.responsible_name.presence || "-")
  json.process_number(@task.legal_case&.internal_number || "-")
  json.client_name(@task.legal_case&.client&.full_name || "-")
end
json.actions do
  json.edit edit_task_path(@task)
  json.index tasks_path
  json.delete task_path(@task)
  json.legal_case(@task.legal_case ? legal_case_path(@task.legal_case) : nil)
end
