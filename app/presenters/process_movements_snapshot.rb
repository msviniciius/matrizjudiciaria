class ProcessMovementsSnapshot
  include Rails.application.routes.url_helpers

  FILTER_KEYS = %i[
    q
    phase_id
    status
    movement_type_id
    nature
    impact
    origin
    from
    to
    responsible_name
    exam_id
    administrative_situation
  ].freeze

  def initialize(process_movements:, reports:, filters:, office:)
    @process_movements = process_movements
    @reports = reports
    @filters = filters.to_h.symbolize_keys
    @office = office
  end

  def as_json(*)
    {
      meta: {
        office_name: office.name,
        total_count: process_movements.size
      },
      filters: FILTER_KEYS.index_with { |key| filters[key].to_s },
      filter_options: filter_options,
      reports: reports_entry,
      process_movements: process_movements.map { |record| movement_entry(record) },
      actions: {
        index: process_movements_path,
        new: new_process_movement_path
      }
    }
  end

  private

  attr_reader :process_movements, :reports, :filters, :office

  def movement_entry(record)
    legal_case = record.process

    {
      id: record.id,
      path: process_movement_path(record),
      edit_path: edit_process_movement_path(record),
      legal_case_path: (legal_case_path(legal_case) if legal_case.present?),
      process_number: legal_case&.internal_number || "-",
      client_name: legal_case&.client&.full_name || "-",
      phase_name: record.phase&.name || "-",
      status_label: legal_case&.status.present? ? enum_label(LegalCase, :status, legal_case.status) : "-",
      movement_type_name: record.movement_type&.name || "-",
      display_title: record.display_title,
      description: record.complementary_description.to_s,
      event_date: record.event_date&.iso8601,
      event_date_label: record.event_date.present? ? I18n.l(record.event_date, format: :short) : "-",
      nature_label: enum_label(ProcessMovement, :nature, record.nature),
      impact_label: enum_label(ProcessMovement, :impact, record.impact),
      origin_label: enum_label(ProcessMovement, :origin, record.origin),
      administrative_situation_label: record.administrative_situation.present? ? enum_label(ProcessMovement, :administrative_situation, record.administrative_situation) : "-",
      responsible_name: legal_case&.responsible_name.presence || "-"
    }
  end

  def filter_options
    {
      phases: ProcessPhase.where(active: true).order(:order, :name).map { |phase| option(phase.id, phase.name) },
      statuses: enum_options(LegalCase, :status),
      movement_types: MovementType.where(active: true).order(:name).map { |movement_type| option(movement_type.id, movement_type.name) },
      natures: enum_options(ProcessMovement, :nature),
      impacts: enum_options(ProcessMovement, :impact),
      origins: enum_options(ProcessMovement, :origin),
      exams: ProcessExam
        .joins(:legal_case)
        .where(legal_cases: { office_id: office.id })
        .where(active: true)
        .order(:scheduled_at)
        .map { |exam| option(exam.id, exam.summary_label) },
      administrative_situations: enum_options(ProcessMovement, :administrative_situation)
    }
  end

  def reports_entry
    {
      por_fase: report_group("Por fase", reports.fetch(:por_fase, {})),
      por_tipo: report_group("Por tipo", reports.fetch(:por_tipo, {})),
      por_natureza: report_group("Por natureza", reports.fetch(:por_natureza, {}), model_class: ProcessMovement, enum_name: :nature),
      por_impacto: report_group("Por impacto", reports.fetch(:por_impacto, {}), model_class: ProcessMovement, enum_name: :impact),
      por_origem: report_group("Por origem", reports.fetch(:por_origem, {}), model_class: ProcessMovement, enum_name: :origin)
    }
  end

  def report_group(title, values, model_class: nil, enum_name: nil)
    entries = values.map do |raw_label, count|
      label = if model_class.present? && enum_name.present?
        enum_label(model_class, enum_name, raw_label)
      else
        raw_label.presence || "Não informado"
      end

      { label: label, count: count }
    end.sort_by { |entry| [ -entry.fetch(:count), entry.fetch(:label).to_s ] }

    {
      title: title,
      total: entries.sum { |entry| entry.fetch(:count).to_i },
      entries: entries
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
end
