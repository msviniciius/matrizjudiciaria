class CaseEvent < ApplicationRecord
  MOVEMENT_TYPE_PHASE_TRANSITIONS = {
    "cadastro" => "atendimento_inicial",
    "documentacao" => "analise_juridica",
    "analise_juridica" => "analise_juridica",
    "estrategia" => "analise_juridica",
    "protocolo_administrativo" => "administrativo",
    "movimentacao_administrativa" => "administrativo",
    "exigencia_administrativa" => "administrativo",
    "protocolo_judicial" => "judicial",
    "movimentacao_judicial" => "judicial",
    "audiencia" => "instrucao",
    "prova" => "instrucao",
    "pericia" => "instrucao",
    "decisao" => "sentenca",
    "recurso" => "recurso",
    "execucao" => "cumprimento_execucao",
    "acordo" => "acordo",
    "pagamento" => "cumprimento_execucao",
    "encerramento" => "encerrado"
  }.freeze

  MOVEMENT_TYPE_STATUS_TRANSITIONS = {
    "exigencia_administrativa" => "aguardando_providencia_escritorio",
    "audiencia" => "aguardando_providencia_escritorio",
    "encerramento" => "encerrado"
  }.freeze

  belongs_to :legal_case
  belongs_to :movement_type, optional: true
  belongs_to :process_exam, optional: true

  enum :entry_kind, {
    andamento: "andamento",
    nota_interna: "nota_interna",
    atualizacao_estrategica: "atualizacao_estrategica"
  }, prefix: true

  validates :description, presence: true
  validates :movement_type, presence: true, if: -> { entry_kind_andamento? && pje_external_id.blank? }
  validates :pje_external_id, uniqueness: true, allow_nil: true

  scope :from_pje, -> { where.not(pje_external_id: nil) }
  scope :by_event_date, -> { order(event_date: :desc, id: :desc) }

  after_commit :sync_modules!, on: [ :create, :update ]

  def phase_after_unified
    return unless entry_kind_andamento?

    from_type = MOVEMENT_TYPE_PHASE_TRANSITIONS[movement_type&.code]
    return from_type if from_type.present?

    legal_case&.phase
  end

  def status_after_unified
    return unless entry_kind_andamento?

    from_type = MOVEMENT_TYPE_STATUS_TRANSITIONS[movement_type&.code]
    return from_type if from_type.present?

    legal_case&.status
  end

  private

  def sync_modules!
    sync_exam_status!
    legal_case.update_snapshot_from_case_event!(self)
    apply_strategic_update!
    create_exam_task_and_deadline_if_needed!
  end

  def sync_exam_status!
    return if process_exam.blank?
    return unless movement_type&.code == "pericia"

    attrs = {}
    attrs[:scheduled_at] = created_at if process_exam.scheduled_at.blank?
    attrs[:status] = "designada" if process_exam.status_nao_designada?

    process_exam.update!(attrs) if attrs.any?
  end

  def apply_strategic_update!
    return unless entry_kind_atualizacao_estrategica?

    previous = legal_case.strategic_notes.to_s
    marker = "[#{created_at.strftime("%d/%m/%Y %H:%M")}] #{description}"
    merged = [ previous, marker ].reject(&:blank?).join("\n")
    legal_case.update_column(:strategic_notes, merged)
  end

  def create_exam_task_and_deadline_if_needed!
    return if process_exam.blank?
    return unless movement_type&.code == "pericia"

    CaseSync::TaskDeadlineCreator.new(legal_case)
      .create_exam_task_and_deadline(process_exam, responsible_name: responsible_name)
  end
end
