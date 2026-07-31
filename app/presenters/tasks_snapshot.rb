class TasksSnapshot
  include Rails.application.routes.url_helpers

  FILTER_KEYS = %i[q status priority responsible_name due_state].freeze

  def initialize(office:, unit:, tasks:, filters:)
    @office = office
    @unit = unit
    @tasks = tasks
    @filters = filters.to_h.symbolize_keys
  end

  def as_json(*)
    {
      meta: { office_name: office.name, unit_name: unit&.name, total_count: tasks.size },
      filters: FILTER_KEYS.index_with { |key| filters[key].to_s },
      filter_options: {
        statuses: enum_options(Task, :status),
        priorities: enum_options(Task, :priority),
        due_states: [
          option("overdue", "Atrasadas"), option("today", "Hoje"),
          option("upcoming", "Próximos 7 dias"), option("without_due_date", "Sem data")
        ]
      },
      tasks: tasks.map { |task| task_entry(task) },
      actions: { index: tasks_path, new: new_task_path }
    }
  end

  private

  attr_reader :office, :unit, :tasks, :filters

  def task_entry(task)
    legal_case = task.legal_case
    {
      id: task.id,
      path: task_path(task),
      edit_path: edit_task_path(task),
      delete_path: task_path(task),
      legal_case_path: legal_case_path(legal_case),
      process_number: legal_case&.internal_number.to_s,
      client_name: legal_case&.client&.full_name.to_s,
      title: task.title.to_s,
      description: task.description.to_s,
      status: task.status.to_s,
      status_label: enum_label(Task, :status, task.status),
      priority: task.priority,
      priority_label: enum_label(Task, :priority, task.priority),
      due_date_label: date_label(task.due_date),
      due_state: due_state(task),
      due_state_label: due_state_label(task),
      responsible_name: task.responsible_name.to_s.presence || "-"
    }
  end

  def due_state(task)
    return "without_due_date" if task.due_date.blank?
    return "overdue" if task.due_date < Date.current
    return "today" if task.due_date == Date.current
    return "upcoming" if task.due_date <= Date.current + 7.days

    "future"
  end

  def due_state_label(task)
    { "without_due_date" => "Sem data", "overdue" => "Atrasada", "today" => "Hoje", "upcoming" => "Próximos 7 dias", "future" => "Futura" }.fetch(due_state(task))
  end

  def enum_options(model_class, enum_name)
    model_class.public_send(enum_name.to_s.pluralize).keys.map { |value| option(value, enum_label(model_class, enum_name, value)) }
  end

  def option(value, label)
    { value: value.to_s, label: label }
  end

  def enum_label(model_class, enum_name, value)
    return "-" if value.blank?

    I18n.t("activerecord.attributes.#{model_class.model_name.i18n_key}.#{enum_name.to_s.pluralize}.#{value}", default: value.to_s.humanize)
  end

  def date_label(value)
    value.present? ? I18n.l(value, format: :short) : "-"
  end
end
