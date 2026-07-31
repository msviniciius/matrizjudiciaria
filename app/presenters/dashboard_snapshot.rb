class DashboardSnapshot
  include Rails.application.routes.url_helpers

  CONTEXT_ITEMS_LIMIT = 6

  def initialize(office:, unit:, all_units_mode:)
    @office = office
    @unit = unit
    @all_units_mode = all_units_mode
  end

  def as_json(*)
    {
      meta: {
        office_name: office.name,
        unit_name: unit&.name,
        syncable_count: legal_cases.syncable.count,
        new_imported_events_count: legal_cases.with_new_imported_events.count
      },
      kpis: kpis,
      critical_queues: critical_queues,
      risk_queue: risk_queue,
      feed: feed,
      distribution: distribution,
      actions: {
        sync: sync_all_cases_path
      }
    }
  end

  private

  attr_reader :office, :unit, :all_units_mode

  def legal_cases
    @legal_cases ||= apply_unit_scope(office.legal_cases)
  end

  def operational_cases
    @operational_cases ||= legal_cases.operational
  end

  def deadlines
    @deadlines ||= Deadline.joins(:legal_case).where(legal_cases: { office_id: office.id }).then { |scope| apply_unit_scope(scope) }
  end

  def tasks
    @tasks ||= Task.joins(:legal_case).where(legal_cases: { office_id: office.id }).then { |scope| apply_unit_scope(scope) }
  end

  def apply_unit_scope(scope)
    return scope if all_units_mode
    return scope.none if unit.blank?

    if scope.klass.column_names.include?("unit_id")
      scope.where(unit_id: unit.id)
    else
      scope.where(legal_cases: { unit_id: unit.id })
    end
  end

  def kpis
    deadline_soon = legal_cases.with_upcoming_deadline
    without_deadline = legal_cases.without_deadline
    at_risk = legal_cases.select(&:health_status_vermelho?)
    overdue_deadlines = deadlines.where("due_date < ?", Date.current).where.not(status: :completed)
    due_today = deadlines.where(due_date: Date.current).where.not(status: :completed)
    tasks_today = tasks.where(due_date: Date.current).where.not(status: :completed)

    {
      deadline_soon: kpi("Prazo próximo", deadline_soon.count, legal_cases_path(deadline_state: "upcoming"), "warning", deadline_soon),
      without_deadline: kpi("Sem prazo", without_deadline.count, legal_cases_path(deadline_state: "without_deadline"), "neutral", without_deadline),
      at_risk: kpi("Em risco", at_risk.count, legal_cases_path(health: "critica"), "danger", at_risk),
      overdue_deadlines: kpi("Prazos vencidos", overdue_deadlines.count, deadlines_path(due_state: "overdue"), "danger", overdue_deadlines),
      due_today: kpi("Prazos hoje", due_today.count, deadlines_path(due_state: "today"), "warning", due_today),
      tasks_today: kpi("Tarefas hoje", tasks_today.count, tasks_path(due_state: "today"), "info", tasks_today)
    }
  end

  def kpi(label, count, path, tone, records)
    { label: label, count: count, path: path, tone: tone, items: context_items(records) }
  end

  def critical_queues
    {
      without_responsible: operational_cases.where(responsible_name: [ nil, "" ]).order(Arel.sql("legal_cases.next_deadline_on ASC NULLS LAST, legal_cases.updated_at DESC")).limit(6).map { |record| case_entry(record) },
      without_next_action: operational_cases.where(next_action: [ nil, "" ]).order(Arel.sql("legal_cases.next_deadline_on ASC NULLS LAST, legal_cases.updated_at DESC")).limit(6).map { |record| next_action_entry(record) },
      overdue_deadlines_without_reason: deadlines.where("deadlines.due_date < ?", Date.current).where.not(status: :completed).where("COALESCE(deadlines.delay_reason, '') = ''").order(due_date: :asc).limit(6).map { |record| deadline_entry(record) }
    }
  end

  def case_entry(record)
    {
      id: record.id,
      internal_number: record.internal_number,
      path: legal_case_path(record),
      responsible_name: record.responsible_name,
      updated_at: record.updated_at.iso8601,
      update_responsible_path: quick_update_case_responsible_path(record)
    }
  end

  def next_action_entry(record)
    case_entry(record).merge(next_action: record.next_action, update_next_action_path: quick_update_case_next_action_path(record))
  end

  def deadline_entry(record)
    {
      id: record.id,
      title: record.title,
      due_date: record.due_date.iso8601,
      legal_case_number: record.legal_case.internal_number,
      path: deadline_path(record),
      update_reason_path: quick_update_deadline_reason_path(record)
    }
  end

  def risk_queue
    due_today = operational_cases.deadline_due_today
    due_in_48_hours = operational_cases.deadline_due_in_48h
    overdue = operational_cases.deadline_overdue
    without_next_action = operational_cases.without_next_action

    {
      due_today: risk("Vence hoje", due_today.count, legal_cases_path(deadline_state: "today", operational: "1"), due_today),
      due_in_48_hours: risk("Próximas 48h", due_in_48_hours.count, legal_cases_path(deadline_state: "next_48_hours", operational: "1"), due_in_48_hours),
      overdue: risk("Atrasados", overdue.count, legal_cases_path(deadline_state: "overdue", operational: "1"), overdue),
      without_next_action: risk("Sem próxima providência", without_next_action.count, legal_cases_path(without_next_action: "1", operational: "1"), without_next_action)
    }
  end

  def risk(label, count, path, records)
    { label: label, count: count, path: path, items: context_items(records) }
  end

  def feed
    movements = ProcessMovement.joins(:process).where(legal_cases: { office_id: office.id }).then { |scope| apply_unit_scope(scope) }.includes(:process, :movement_type).order(event_date: :desc, created_at: :desc).limit(8)
    events = CaseEvent.where.not(pje_external_id: nil).joins(:legal_case).where(legal_cases: { office_id: office.id }).then { |scope| apply_unit_scope(scope) }.includes(:legal_case, :movement_type).order(event_date: :desc, created_at: :desc).limit(5)

    TimelineBuilder.build_compact(process_movements: movements, case_events: events, limit: 10).map do |item|
      {
        title: item[:title].presence || "Andamento sem título",
        origin: item[:origin],
        internal_number: item[:internal_number],
        date: item[:date]&.iso8601,
        highlight: item[:highlight],
        path: legal_case_path(item[:process_id])
      }
    end
  end

  def distribution
    phase_counts = legal_cases.group(:phase).count
    status_counts = legal_cases.group(:status).count

    {
      phase: phase_counts.map do |phase, count|
        { label: phase_label(phase), count: count, path: legal_cases_path(phase: phase), items: context_items(legal_cases.where(phase: phase)) }
      end,
      status: status_counts.map do |status, count|
        { label: status_label(status), count: count, path: legal_cases_path(status: status), items: context_items(legal_cases.where(status: status)) }
      end
    }
  end

  def context_items(records)
    limited_records =
      if records.respond_to?(:limit)
        relation = records.limit(CONTEXT_ITEMS_LIMIT)
        relation = relation.includes(:legal_case) unless relation.klass == LegalCase
        relation.to_a
      else
        records.first(CONTEXT_ITEMS_LIMIT)
      end

    limited_records
      .filter_map { |record| record.is_a?(LegalCase) ? record : record.try(:legal_case) }
      .uniq(&:id)
      .map { |record| context_case_entry(record) }
  end

  def context_case_entry(record)
    {
      id: record.id,
      internal_number: record.internal_number,
      path: legal_case_path(record),
      responsible_name: record.responsible_name.to_s,
      next_action: record.next_action.to_s,
      update_responsible_path: quick_update_case_responsible_path(record),
      update_next_action_path: quick_update_case_next_action_path(record)
    }
  end

  def phase_label(value)
    I18n.t("activerecord.attributes.legal_case.phases.#{value}", default: value.to_s.humanize)
  end

  def status_label(value)
    I18n.t("activerecord.attributes.legal_case.statuses.#{value}", default: value.to_s.humanize)
  end
end
