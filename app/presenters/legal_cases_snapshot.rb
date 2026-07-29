class LegalCasesSnapshot
  include Rails.application.routes.url_helpers

  FILTER_KEYS = %i[q phase status priority responsible_name deadline_state].freeze
  DEADLINE_STATE_OPTIONS = [
    [ "Atrasado", "overdue" ],
    [ "Vence hoje", "today" ],
    [ "Próximos 7 dias", "upcoming" ],
    [ "Sem prazo", "without_deadline" ]
  ].freeze

  def initialize(office:, unit:, all_units_mode:, filters:)
    @office = office
    @unit = unit
    @all_units_mode = all_units_mode
    @filters = filters.to_h.symbolize_keys
  end

  def as_json(*)
    {
      meta: {
        office_name: office.name,
        unit_name: unit&.name,
        total_count: legal_cases.count
      },
      filters: normalized_filters,
      filter_options: filter_options,
      legal_cases: legal_cases.map { |record| legal_case_entry(record) },
      actions: {
        index: legal_cases_path,
        new: new_legal_case_path,
        daily_closure: daily_closure_legal_cases_path
      }
    }
  end

  private

  attr_reader :office, :unit, :all_units_mode, :filters

  def legal_cases
    @legal_cases ||= LegalCaseQuery.new(scoped_cases, filters).call.includes(:client, :legal_area).order(updated_at: :desc)
  end

  def scoped_cases
    scope_by_unit(office.legal_cases)
  end

  def scope_by_unit(scope)
    return scope if all_units_mode || unit.blank?

    scope.where(unit_id: unit.id)
  end

  def normalized_filters
    FILTER_KEYS.index_with { |key| filters[key].to_s }
  end

  def filter_options
    {
      q: [],
      phase: enum_options(:phase),
      status: enum_options(:status),
      priority: enum_options(:priority),
      responsible_name: [],
      deadline_state: DEADLINE_STATE_OPTIONS.map { |label, value| { label: label, value: value } }
    }
  end

  def enum_options(enum_name)
    LegalCase.public_send(enum_name.to_s.pluralize).keys.map do |value|
      {
        label: enum_label(enum_name, value),
        value: value
      }
    end
  end

  def legal_case_entry(record)
    {
      id: record.id,
      path: legal_case_path(record),
      internal_number: record.internal_number,
      client_name: record.client.full_name,
      legal_area_name: record.legal_area&.name || "-",
      status: record.status,
      status_label: enum_label(:status, record.status),
      phase: record.phase,
      priority: record.priority,
      responsible_name: record.responsible_name.presence || "-",
      last_movement: record.last_movement.presence || "-",
      next_deadline_on: record.next_deadline_on&.iso8601,
      next_deadline_label: deadline_label(record.next_deadline_on),
      deadline_tone: deadline_tone(record.next_deadline_on),
      has_new_imported_events: new_imported_event_ids.include?(record.id)
    }
  end

  def new_imported_event_ids
    @new_imported_event_ids ||= legal_cases.reorder(nil).with_new_imported_events.pluck(:id)
  end

  def enum_label(enum_name, value)
    I18n.t(
      "activerecord.attributes.legal_case.#{enum_name.to_s.pluralize}.#{value}",
      default: value.to_s.humanize
    )
  end

  def deadline_label(date)
    date.present? ? I18n.l(date, format: :short) : "-"
  end

  def deadline_tone(date)
    return "none" if date.blank?
    return "overdue" if date < Date.current
    return "today" if date == Date.current

    "upcoming"
  end
end
