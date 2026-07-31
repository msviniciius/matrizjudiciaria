class DeadlinesSnapshot
  include Rails.application.routes.url_helpers

  FILTER_KEYS = %i[q status priority deadline_type due_state].freeze

  def initialize(office:, unit:, deadlines:, filters:)
    @office = office
    @unit = unit
    @deadlines = deadlines
    @filters = filters.to_h.symbolize_keys
  end

  def as_json(*)
    {
      meta: {
        office_name: office.name,
        unit_name: unit&.name,
        total_count: deadlines.size
      },
      filters: FILTER_KEYS.index_with { |key| filters[key].to_s },
      filter_options: filter_options,
      deadlines: deadlines.map { |deadline| deadline_entry(deadline) },
      actions: {
        index: deadlines_path,
        new: new_deadline_path
      }
    }
  end

  private

  attr_reader :office, :unit, :deadlines, :filters

  def deadline_entry(deadline)
    legal_case = deadline.legal_case

    {
      id: deadline.id,
      path: deadline_path(deadline),
      edit_path: edit_deadline_path(deadline),
      delete_path: deadline_path(deadline),
      legal_case_path: (legal_case_path(legal_case) if legal_case.present?),
      process_number: legal_case&.internal_number || "-",
      client_name: legal_case&.client&.full_name || "-",
      title: deadline.title,
      deadline_type_label: deadline.deadline_type.present? ? enum_label(Deadline, :deadline_type, deadline.deadline_type) : "-",
      due_date: deadline.due_date&.iso8601,
      due_date_label: date_label(deadline.due_date),
      due_state: due_state(deadline),
      due_state_label: due_state_label(deadline),
      status: deadline.status,
      status_label: enum_label(Deadline, :status, deadline.status),
      priority: deadline.priority,
      priority_label: deadline.priority.present? ? enum_label(Deadline, :priority, deadline.priority) : "-",
      extended_at_label: date_label(deadline.extended_at),
      responsible_name: deadline.responsible_name.presence || "-",
      delay_reason: deadline.delay_reason.to_s
    }
  end

  def filter_options
    {
      statuses: enum_options(Deadline, :status),
      priorities: enum_options(Deadline, :priority),
      deadline_types: enum_options(Deadline, :deadline_type),
      due_states: [
        option("overdue", "Atrasado"),
        option("today", "Hoje"),
        option("upcoming", "Próximos 7 dias"),
        option("without_due_date", "Sem data")
      ]
    }
  end

  def due_state(deadline)
    return "without_due_date" if deadline.due_date.blank?
    return "overdue" if deadline.due_date < Date.current
    return "today" if deadline.due_date == Date.current
    return "upcoming" if deadline.due_date <= Date.current + 7.days

    "future"
  end

  def due_state_label(deadline)
    case due_state(deadline)
    when "without_due_date" then "Sem data"
    when "overdue" then "Atrasado"
    when "today" then "Hoje"
    when "upcoming" then "Próximos 7 dias"
    else "Futuro"
    end
  end

  def enum_options(model_class, enum_name)
    model_class.public_send(enum_name.to_s.pluralize).keys.map do |value|
      option(value, enum_label(model_class, enum_name, value))
    end
  end

  def option(value, label)
    { value: value.to_s, label: label }
  end

  def enum_label(model_class, enum_name, value)
    return "-" if value.blank?

    I18n.t(
      "activerecord.attributes.#{model_class.model_name.i18n_key}.#{enum_name.to_s.pluralize}.#{value}",
      default: value.to_s.humanize
    )
  end

  def date_label(value)
    value.present? ? I18n.l(value, format: :short) : "-"
  end
end
