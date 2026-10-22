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
      deadlines: ordered_deadlines.map { |deadline| deadline_entry(deadline) },
      actions: {
        index: deadlines_path,
        new: new_deadline_path
      }
    }
  end

  private

  attr_reader :office, :unit, :deadlines, :filters

  def ordered_deadlines
    deadlines.sort_by { |deadline| [ deadline.due_date.present? ? 0 : 1, deadline.due_date || Date.new(9999, 12, 31), -deadline.created_at.to_i ] }
  end

  def deadline_entry(deadline)
    legal_case = deadline.legal_case

    {
      id: deadline.id,
      path: deadline_path(deadline),
      edit_path: edit_deadline_path(deadline),
      delete_path: deadline_path(deadline),
      complete_path: cumprir_deadline_path(deadline),
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
      delay_reason: deadline.delay_reason.to_s,
      legal_state: legal_state(deadline),
      legal_state_label: legal_state_label(deadline),
      origin: origin(deadline),
      origin_label: origin_label(deadline),
      science_date: science_date(deadline)&.iso8601,
      science_date_label: date_label(science_date(deadline)),
      expediente: expediente_entry(deadline.expediente),
      expediente_id: deadline.expediente_id,
      ciencia_path: (ciencias_path if deadline.expediente.present? && deadline.expediente.ciencia.blank?)
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

  def legal_state(deadline)
    return if deadline.expediente.blank?
    return "awaiting_science" if deadline.expediente.ciencia.blank?
    return "completed" if deadline.status_completed?
    return "overdue" if deadline.due_date.present? && deadline.due_date < Date.current

    "in_progress"
  end

  def legal_state_label(deadline)
    {
      "awaiting_science" => "Aguardando ciência",
      "in_progress" => "Em curso",
      "overdue" => "Vencido",
      "completed" => "Concluído"
    }.fetch(legal_state(deadline), "-")
  end

  def origin(deadline)
    deadline.expediente&.origem || "manual"
  end

  def origin_label(deadline)
    return "Manual" if deadline.expediente.blank?

    enum_label(Expediente, :origem, deadline.expediente.origem)
  end

  def science_date(deadline)
    deadline.expediente&.ciencia&.data_ciencia
  end

  def expediente_entry(expediente)
    return nil if expediente.blank?

    {
      id: expediente.id,
      description: expediente.descricao,
      type: expediente.tipo,
      type_label: enum_label(Expediente, :tipo, expediente.tipo),
      availability_date: expediente.data_disponibilizacao&.iso8601,
      availability_date_label: date_label(expediente.data_disponibilizacao),
      days: expediente.quantidade_dias,
      counting: expediente.contagem,
      origin: expediente.origem,
      reference: expediente.referencia_externa
    }
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
