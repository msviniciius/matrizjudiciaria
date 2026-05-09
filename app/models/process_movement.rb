class ProcessMovement < ApplicationRecord
  belongs_to :process, class_name: "LegalCase"
  belongs_to :phase, class_name: "ProcessPhase"
  belongs_to :movement_type
  belongs_to :movement_template, optional: true
  belongs_to :exam, class_name: "ProcessExam", optional: true
  belongs_to :next_phase, class_name: "ProcessPhase", optional: true

  has_many :audits, class_name: "ProcessMovementAudit", dependent: :destroy

  enum :nature, {
    fato_processual: "fato_processual",
    fato_administrativo: "fato_administrativo",
    nota_interna: "nota_interna",
    atualizacao_estrategica: "atualizacao_estrategica"
  }, prefix: true

  enum :impact, {
    sem_impacto_de_fase: "sem_impacto_de_fase",
    altera_fase: "altera_fase",
    exige_providencia_imediata: "exige_providencia_imediata",
    exige_revisao_estrategica: "exige_revisao_estrategica"
  }, prefix: true

  enum :origin, {
    manual: "manual",
    tribunal: "tribunal",
    administrativo: "administrativo",
    interno: "interno",
    cliente: "cliente",
    integracao: "integracao"
  }, prefix: true

  enum :administrative_situation, {
    em_analise: "em_analise",
    em_exigencia: "em_exigencia",
    deferido: "deferido",
    indeferido: "indeferido",
    aguardando_protocolo: "aguardando_protocolo",
    exigencia_cumprida: "exigencia_cumprida",
    recurso_em_andamento: "recurso_em_andamento",
    deferido_parcialmente: "deferido_parcialmente",
    implantacao_pendente: "implantacao_pendente",
    pericia_designada: "pericia_designada",
    avaliacao_social_designada: "avaliacao_social_designada"
  }, prefix: true

  validates :display_title, :event_date, :nature, :impact, :origin, presence: true
  validates :administrative_situation, inclusion: { in: administrative_situations.keys }, allow_blank: true
  validates :override_reason, presence: true, if: :manual_override?
  validate :exam_is_required_when_template_requires
  validate :administrative_situation_required_for_administrative_previdenciario
  validate :exception_mode_requires_authorization

  before_validation :apply_defaults_from_template
  before_validation :fallback_phase_from_process
  before_validation :fallback_exam_from_process

  after_commit :sync_modules!, on: [ :create, :update ]
  after_create_commit { create_audit!("create", previous_changes) }
  after_update_commit { create_audit!("update", previous_changes) }

  scope :recent, -> { order(event_date: :desc, id: :desc) }
  scope :active, -> { where(active: true) }

  private

  def apply_defaults_from_template
    return if movement_template.blank?

    self.phase_id ||= movement_template.phase_id
    self.movement_type_id ||= movement_template.movement_type_id
    self.nature ||= movement_template.nature_default
    self.impact ||= movement_template.impact_default
    self.updates_phase = movement_template.updates_phase if updates_phase.nil?
    self.next_phase_id ||= movement_template.next_phase_id
    self.creates_task = movement_template.creates_task if creates_task.nil?
    self.creates_deadline = movement_template.creates_deadline if creates_deadline.nil?
    self.display_title ||= movement_template.name
    self.origin ||= "manual"
  end

  def fallback_phase_from_process
    return if phase_id.present?
    return if process.blank? || process.phase.blank?

    phase_record = ProcessPhase.find_by(code: process.phase)
    self.phase_id = phase_record&.id
  end

  def exam_is_required_when_template_requires
    return if movement_template.blank?
    return unless movement_template.requires_exam_id?

    if exam_id.blank?
      errors.add(:base, "Este modelo exige perícia ativa no processo. Cadastre a perícia no processo antes de salvar o andamento.")
    end
  end

  def fallback_exam_from_process
    return if exam_id.present?
    return if process.blank?

    self.exam = process.process_exams.active.order(:scheduled_at).first
  end

  def administrative_situation_required_for_administrative_previdenciario
    return unless nature_fato_administrativo?

    processo_previdenciario = process&.legal_area&.name.to_s.downcase.include?("previdenci") ||
      process&.process_type&.name.to_s.downcase.include?("previdenci")
    return unless processo_previdenciario

    if administrative_situation.blank?
      errors.add(:administrative_situation, "é obrigatória para andamento administrativo previdenciário")
    end
  end

  def exception_mode_requires_authorization
    return unless manual_override?

    unless exception_authorized?
      errors.add(:exception_authorized, "deve ser autorizado para uso do modo de exceção")
    end
  end

  def sync_modules!
    sync_exam_status!
    process.update_snapshot_from_process_movement!(self)
    create_task_if_needed!
    create_deadline_if_needed!
  rescue StandardError => error
    ProcessMovementAudit.create!(
      process_movement: self,
      action: "automation_failure",
      changed_fields: { "error" => error.class.name, "message" => error.message },
      justification: "Falha na automação pós-andamento"
    )
  end

  def sync_exam_status!
    return if exam.blank?

    mapped_status = case movement_template&.code || movement_type&.code
    when "pericia_designada" then "designada"
    when "pericia_redesignada" then "redesignada"
    when "pericia_realizada" then "realizada"
    when "laudo_pericial_juntado" then "laudo_juntado"
    end

    attrs = {}
    attrs[:status] = mapped_status if mapped_status.present?
    attrs[:scheduled_at] = event_date if mapped_status == "redesignada"
    exam.update!(attrs) if attrs.any?
  end

  def create_task_if_needed!
    return unless creates_task?

    task_title = movement_template&.task_template_name.presence || "Providência: #{display_title}"
    due_date = exam&.scheduled_at&.to_date || event_date.to_date

    Task.find_or_create_by!(legal_case_id: process_id, title: task_title, due_date: due_date) do |task|
      task.status = "pending"
      task.priority = "high"
      task.description = complementary_description.presence || "Tarefa criada automaticamente pelo andamento processual."
      task.responsible_name = process.responsible_name
    end
  end

  def create_deadline_if_needed!
    return unless creates_deadline?

    title = movement_template&.deadline_template_name.presence || "Prazo: #{display_title}"
    deadline_type = "internal"
    base_date = exam&.scheduled_at&.to_date || event_date.to_date
    rule = process.office&.deadline_settings&.active&.find_by(deadline_type: deadline_type)
    due_date = base_date + rule&.days_to_due.to_i.days

    Deadline.find_or_create_by!(legal_case_id: process_id, title: title, due_date: due_date) do |deadline|
      deadline.deadline_type = deadline_type
      deadline.status = "pending"
      deadline.priority = rule&.default_priority.presence || "high"
      deadline.delay_reason = rule&.justification_hint
    end
  end

  def create_audit!(action, changed_fields)
    ProcessMovementAudit.create!(
      process_movement: self,
      action: action,
      changed_fields: changed_fields,
      justification: (manual_override? ? override_reason : nil),
      changed_by_user_id: override_by_user_id || created_by_user_id
    )
  end
end
