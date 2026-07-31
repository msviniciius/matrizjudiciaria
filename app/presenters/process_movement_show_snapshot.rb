class ProcessMovementShowSnapshot
  include Rails.application.routes.url_helpers

  def initialize(process_movement:)
    @process_movement = process_movement
  end

  def as_json(*)
    {
      movement: movement_entry,
      legal_case: legal_case_entry,
      details: details,
      automation: automation,
      description: process_movement.complementary_description.to_s,
      audits: audits.map { |audit| audit_entry(audit) },
      actions: actions
    }
  end

  private

  attr_reader :process_movement

  def movement_entry
    {
      id: process_movement.id,
      display_title: process_movement.display_title,
      event_date: process_movement.event_date&.iso8601,
      event_date_label: date_label(process_movement.event_date),
      phase_name: process_movement.phase&.name || "-",
      movement_type_name: process_movement.movement_type&.name || "-",
      movement_template_name: process_movement.movement_template&.name || "-",
      nature_label: enum_label(ProcessMovement, :nature, process_movement.nature),
      impact_label: enum_label(ProcessMovement, :impact, process_movement.impact),
      origin_label: enum_label(ProcessMovement, :origin, process_movement.origin),
      administrative_situation_label: process_movement.administrative_situation.present? ? enum_label(ProcessMovement, :administrative_situation, process_movement.administrative_situation) : "-",
      active: process_movement.active?
    }
  end

  def legal_case_entry
    legal_case = process_movement.process

    {
      id: legal_case.id,
      internal_number: legal_case.internal_number,
      external_number: legal_case.external_number,
      client_name: legal_case.client&.full_name.presence || "Cliente não informado",
      status_label: enum_label(LegalCase, :status, legal_case.status),
      phase_label: enum_label(LegalCase, :phase, legal_case.phase),
      responsible_name: legal_case.responsible_name.presence || "-",
      path: legal_case_path(legal_case),
      client_path: (client_path(legal_case.client) if legal_case.client.present?)
    }
  end

  def details
    [
      detail("Processo", process_movement.process.internal_number),
      detail("Cliente", process_movement.process.client&.full_name),
      detail("Fase do andamento", process_movement.phase&.name),
      detail("Tipo", process_movement.movement_type&.name),
      detail("Modelo", process_movement.movement_template&.name),
      detail("Perícia", process_movement.exam&.summary_label),
      detail("Natureza", enum_label(ProcessMovement, :nature, process_movement.nature)),
      detail("Impacto", enum_label(ProcessMovement, :impact, process_movement.impact)),
      detail("Origem", enum_label(ProcessMovement, :origin, process_movement.origin)),
      detail("Situação administrativa", process_movement.administrative_situation.present? ? enum_label(ProcessMovement, :administrative_situation, process_movement.administrative_situation) : nil),
      detail("Data", date_label(process_movement.event_date))
    ]
  end

  def automation
    {
      updates_phase: process_movement.updates_phase?,
      next_phase_name: process_movement.next_phase&.name || "-",
      creates_task: process_movement.creates_task?,
      creates_deadline: process_movement.creates_deadline?
    }
  end

  def audits
    @audits ||= process_movement.audits.order(created_at: :desc)
  end

  def audit_entry(audit)
    {
      id: audit.id,
      action: audit.action,
      action_label: audit.action.to_s.humanize,
      created_at: audit.created_at&.iso8601,
      created_at_label: date_label(audit.created_at),
      justification: audit.justification.presence || "-",
      changed_fields_count: audit.changed_fields.to_h.size,
      changed_fields: audit.changed_fields.to_h.keys.map(&:to_s).sort
    }
  end

  def actions
    {
      index: process_movements_path,
      edit: edit_process_movement_path(process_movement),
      delete: process_movement_path(process_movement),
      legal_case: legal_case_path(process_movement.process)
    }
  end

  def detail(label, raw_value)
    {
      label: label,
      value: raw_value.presence || "Não informado"
    }
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
