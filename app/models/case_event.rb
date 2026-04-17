class CaseEvent < ApplicationRecord
  belongs_to :legal_case
  belongs_to :movement_type, optional: true
  belongs_to :process_exam, optional: true

  enum :entry_kind, {
    andamento: "andamento",
    nota_interna: "nota_interna",
    atualizacao_estrategica: "atualizacao_estrategica"
  }, prefix: true

  enum :event_type, {
    initial_contact: "initial_contact",
    documents_received: "documents_received",
    legal_analysis: "legal_analysis",
    filing: "filing",
    hearing: "hearing",
    decision: "decision",
    appeal: "appeal",
    client_contact: "client_contact",
    phase_changed: "phase_changed",
    status_changed: "status_changed",
    case_closed: "case_closed",
    requerimento_administrativo_protocolado: "requerimento_administrativo_protocolado",
    exigencia_administrativa_emitida: "exigencia_administrativa_emitida",
    peticao_inicial_protocolada: "peticao_inicial_protocolada",
    contestacao_apresentada: "contestacao_apresentada",
    audiencia_designada: "audiencia_designada",
    sentenca_proferida: "sentenca_proferida",
    recurso_interposto: "recurso_interposto",
    rpv_expedida: "rpv_expedida",
    pericia_designada: "pericia_designada",
    pericia_redesignada: "pericia_redesignada",
    pericia_realizada: "pericia_realizada",
    laudo_pericial_juntado: "laudo_pericial_juntado"
  }, prefix: true

  validates :event_type, :occurred_at, :description, presence: true
  validates :event_type, inclusion: { in: event_types.keys }
  validates :movement_type, presence: true, if: :entry_kind_andamento?

  after_commit :sync_modules!, on: [ :create, :update ]

  private

  def sync_modules!
    sync_exam_status!
    legal_case.update_snapshot_from_case_event!(self)
    apply_strategic_update!
    create_exam_task_and_deadline_if_needed!
  end

  def sync_exam_status!
    return if process_exam.blank?

    mapped_status =
      case event_type
      when "pericia_designada" then "designada"
      when "pericia_redesignada" then "redesignada"
      when "pericia_realizada" then "realizada"
      when "laudo_pericial_juntado" then "laudo_juntado"
      end

    attrs = {}
    attrs[:status] = mapped_status if mapped_status.present?
    attrs[:scheduled_at] = occurred_at if event_type == "pericia_redesignada" && process_exam.scheduled_at.blank?

    process_exam.update!(attrs) if attrs.any?
  end

  def apply_strategic_update!
    return unless entry_kind_atualizacao_estrategica?

    previous = legal_case.strategic_notes.to_s
    marker = "[#{occurred_at.strftime("%d/%m/%Y %H:%M")}] #{description}"
    merged = [ previous, marker ].reject(&:blank?).join("\n")
    legal_case.update_column(:strategic_notes, merged)
  end

  def create_exam_task_and_deadline_if_needed!
    return if process_exam.blank?
    return unless [ "pericia_designada", "pericia_redesignada" ].include?(event_type)

    due_date = process_exam.scheduled_at&.to_date
    return if due_date.blank?

    title_base = "Providenciar perícia #{process_exam.exam_nature.humanize.downcase}"

    Task.find_or_create_by!(
      legal_case_id: legal_case_id,
      title: title_base,
      due_date: due_date
    ) do |task|
      task.status = "pending"
      task.priority = "high"
      task.description = "Tarefa criada automaticamente a partir do andamento de perícia."
    end

    Deadline.find_or_create_by!(
      legal_case_id: legal_case_id,
      title: "Prazo da perícia",
      due_date: due_date
    ) do |deadline|
      deadline.deadline_type = "expert_exam"
      deadline.status = "pending"
      deadline.priority = "high"
      deadline.start_date = Date.current
      deadline.responsible_name = responsible_name
    end
  end
end
