class LegalCaseShowSnapshot
  include Rails.application.routes.url_helpers

  def initialize(legal_case:)
    @legal_case = legal_case
  end

  def as_json(*)
    {
      case: case_entry,
      alerts: alerts,
      next_action: next_action,
      timeline: timeline_items.map { |item| timeline_entry(item) },
      deadlines: deadlines.map { |deadline| deadline_entry(deadline) },
      tasks: tasks.map { |task| task_entry(task) },
      exams: exams.map { |exam| exam_entry(exam) },
      actions: actions
    }
  end

  private

  attr_reader :legal_case

  def case_entry
    {
      id: legal_case.id,
      internal_number: legal_case.internal_number,
      external_number: legal_case.external_number,
      client_name: legal_case.client&.full_name.presence || "Cliente não informado",
      phase: legal_case.phase,
      phase_label: enum_label(LegalCase, :phase, legal_case.phase),
      status: legal_case.status,
      status_label: enum_label(LegalCase, :status, legal_case.status),
      priority: legal_case.priority,
      priority_label: enum_label(LegalCase, :priority, legal_case.priority),
      responsible_name: legal_case.responsible_name.presence || "Não definido",
      legal_area_name: legal_case.legal_area&.name || "-",
      process_type_name: legal_case.process_type&.name || "-",
      court_name: legal_case.court&.name || "-",
      district_name: legal_case.district&.name || "-",
      claim_value: legal_case.claim_value,
      opposing_party: legal_case.opposing_party.presence || "-",
      tem_pericia: legal_case.tem_pericia?
    }
  end

  def alerts
    {
      deadline_near: legal_case.prazo_alerta?,
      deadline_overdue: legal_case.deadline_overdue?,
      exam_pending: legal_case.pericia_alerta?,
      next_action_warning: legal_case.next_action_warning?,
      stale_last_movement: legal_case.stale_last_movement?,
      health_status: legal_case.health_status,
      has_new_imported_events: legal_case.has_new_imported_events?
    }
  end

  def next_action
    {
      description: legal_case.next_action.presence || "Não definida",
      deadline_on: legal_case.next_deadline_on&.iso8601,
      deadline_label: date_label(legal_case.next_deadline_on, fallback: "Não definido"),
      last_movement_at: legal_case.last_movement_at&.iso8601,
      last_movement_label: date_label(legal_case.last_movement_at, fallback: "Sem registro")
    }
  end

  def timeline_items
    @timeline_items ||= TimelineBuilder.build(
      process_movements: process_movements,
      case_events: case_events
    )
  end

  def process_movements
    @process_movements ||= legal_case.process_movements
      .includes(:movement_type, :movement_template, :exam, :phase, :next_phase)
      .recent
  end

  def case_events
    @case_events ||= legal_case.case_events
      .includes(:movement_type, :process_exam)
      .order(created_at: :desc)
  end

  def deadlines
    @deadlines ||= legal_case.deadlines.order(due_date: :asc)
  end

  def tasks
    @tasks ||= legal_case.tasks.order(due_date: :asc)
  end

  def exams
    @exams ||= legal_case.process_exams.order(Arel.sql("scheduled_at IS NULL, scheduled_at ASC"))
  end

  def timeline_entry(item)
    {
      id: timeline_item_id(item),
      source: item.fetch(:source).to_s,
      source_label: timeline_source_label(item),
      title: item.fetch(:title),
      description: item[:description],
      occurred_at: item[:date]&.iso8601,
      occurred_at_label: date_label(item[:date]),
      movement_type: item[:movement_type],
      origin: item[:origin],
      highlight: item.fetch(:highlight),
      nature: item[:nature],
      administrative_situation: item[:administrative_situation],
      exam_summary: item[:exam]&.summary_label
    }
  end

  def deadline_entry(deadline)
    {
      id: deadline.id,
      title: deadline.title,
      due_date: deadline.due_date&.iso8601,
      due_date_label: date_label(deadline.due_date),
      status: deadline.status,
      status_label: enum_label(Deadline, :status, deadline.status),
      priority: deadline.priority,
      priority_label: enum_label(Deadline, :priority, deadline.priority),
      deadline_type: deadline.deadline_type,
      deadline_type_label: enum_label(Deadline, :deadline_type, deadline.deadline_type),
      responsible_name: deadline.responsible_name.presence || "-",
      delay_reason: deadline.delay_reason.presence || "-",
      path: deadline_path(deadline)
    }
  end

  def task_entry(task)
    {
      id: task.id,
      title: task.title,
      description: task.description,
      due_date: task.due_date&.iso8601,
      due_date_label: date_label(task.due_date),
      status: task.status,
      status_label: enum_label(Task, :status, task.status),
      priority: task.priority,
      priority_label: enum_label(Task, :priority, task.priority),
      responsible_name: task.responsible_name.presence || "-",
      path: task_path(task)
    }
  end

  def exam_entry(exam)
    {
      id: exam.id,
      nature: exam.exam_nature,
      nature_label: enum_label(ProcessExam, :exam_nature, exam.exam_nature),
      scope: exam.exam_scope,
      scope_label: enum_label(ProcessExam, :exam_scope, exam.exam_scope),
      scheduled_at: exam.scheduled_at&.iso8601,
      scheduled_label: exam.scheduled_label,
      status: exam.status,
      status_label: enum_label(ProcessExam, :status, exam.status),
      location: exam.location.presence || "-",
      expert_name: exam.expert_name.presence || "-",
      notes: exam.notes,
      active: exam.active?,
      path: edit_process_exam_path(exam)
    }
  end

  def actions
    {
      index: legal_cases_path,
      edit: edit_legal_case_path(legal_case),
      pdf: pdf_legal_case_path(legal_case),
      calendar: google_calendar_legal_case_path(legal_case),
      new_movement: new_process_movement_path(process_id: legal_case.id),
      new_deadline: new_deadline_path(legal_case_id: legal_case.id),
      new_task: new_task_path(legal_case_id: legal_case.id),
      new_exam: (new_legal_case_process_exam_path(legal_case) if legal_case.tem_pericia?),
      sync: sync_action
    }
  end

  def sync_action
    return unless legal_case.external_number.present?

    { path: sync_legal_case_path(legal_case), method: "post" }
  end

  def timeline_item_id(item)
    item[:source] == :process_movement ? item[:process_movement_id] : item[:case_event_id]
  end

  def timeline_source_label(item)
    return "Andamento" if item[:source] == :process_movement

    item[:origin]
  end

  def enum_label(model_class, enum_name, value)
    return "" if value.blank?

    I18n.t(
      "activerecord.attributes.#{model_class.model_name.i18n_key}.#{enum_name.to_s.pluralize}.#{value}",
      default: value.to_s.humanize
    )
  end

  def date_label(value, fallback: "-")
    value.present? ? I18n.l(value, format: :short) : fallback
  end
end
