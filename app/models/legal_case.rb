class LegalCase < ApplicationRecord
  OFFICIAL_PHASES = %w[
    atendimento_inicial
    analise_juridica
    administrativo
    judicial
    instrucao
    sentenca
    recurso
    cumprimento_execucao
    acordo
    encerrado
  ].freeze

  OFFICIAL_STATUSES = %w[
    ativo
    aguardando_providencia_escritorio
    aguardando_cliente
    aguardando_terceiros
    suspenso
    arquivado
    encerrado
  ].freeze

  belongs_to :client
  belongs_to :legal_area, optional: true
  belongs_to :process_type, optional: true
  belongs_to :court, optional: true
  belongs_to :district, optional: true

  has_many :case_events, dependent: :destroy
  has_many :process_movements, foreign_key: :process_id, dependent: :destroy
  has_many :deadlines, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :process_exams, dependent: :destroy

  enum :status, OFFICIAL_STATUSES.index_with(&:itself), prefix: true

  enum :priority, {
    low: "low",
    medium: "medium",
    high: "high",
    urgent: "urgent"
  }, prefix: true

  enum :phase, OFFICIAL_PHASES.index_with(&:itself), prefix: true

  before_validation :normalize_legacy_phase_and_status

  validates :internal_number, :legal_area_id, :process_type_id, :court_id, :district_id, :phase, :status, presence: true
  validates :internal_number, uniqueness: true
  validates :status, inclusion: { in: statuses.keys }
  validates :priority, inclusion: { in: priorities.keys }, allow_blank: true
  validates :phase, inclusion: { in: phases.keys }

  scope :with_upcoming_deadline, ->(days = 7) { where(next_deadline_on: Date.current..(Date.current + days.to_i.days)) }
  scope :without_deadline, -> { where(next_deadline_on: nil) }
  scope :with_pericia, -> { where(tem_pericia: true) }

  def self.with_pending_requirement
    joins(:process_movements)
      .where(process_movements: { administrative_situation: "em_exigencia", active: true })
      .distinct
  end

  def refresh_next_deadline!
    next_open_deadline = deadlines.where.not(status: [ "completed", "overdue" ]).order(:due_date).first
    update_column(:next_deadline_on, next_open_deadline&.due_date)
  end

  def update_snapshot_from_case_event!(event)
    latest_movement = case_events
      .where(entry_kind: "andamento")
      .order(occurred_at: :desc, id: :desc)
      .first

    attrs = {
      last_movement: latest_movement&.description,
      last_movement_at: latest_movement&.occurred_at,
      next_action: event.next_action.presence || next_action,
      next_deadline_on: deadlines.where.not(status: [ "completed", "overdue" ]).order(:due_date).pick(:due_date)
    }

    attrs[:phase] = event.phase_after if event.phase_after.present? && self.class.phases.key?(event.phase_after)
    attrs[:status] = event.status_after if event.status_after.present? && self.class.statuses.key?(event.status_after)

    update!(attrs.compact)
  end

  def update_snapshot_from_process_movement!(movement)
    attrs = {
      last_movement: movement.display_title,
      last_movement_at: movement.event_date,
      next_deadline_on: deadlines.where.not(status: [ "completed", "overdue" ]).order(:due_date).pick(:due_date)
    }

    if movement.impact_exige_providencia_imediata?
      attrs[:status] = "aguardando_providencia_escritorio"
      attrs[:next_action] = movement.complementary_description.presence || movement.display_title
    elsif movement.impact_exige_revisao_estrategica?
      attrs[:next_action] = "Revisar estratégia: #{movement.display_title}"
    end

    if movement.updates_phase? && movement.next_phase.present? && self.class.phases.key?(movement.next_phase.code)
      attrs[:phase] = movement.next_phase.code
    end

    if movement.manual_override?
      attrs[:next_action] = movement.override_reason if movement.override_reason.present?
    end

    update!(attrs.compact)
  end

  def prazo_alerta?
    next_deadline_on.present? && next_deadline_on <= Date.current + 7.days
  end

  def pericia_alerta?
    process_exams.where(status: [ "designada", "redesignada", "laudo_pendente" ], active: true).exists?
  end

  def responsavel_atual
    responsible_name
  end

  def fase_atual
    phase
  end

  def status_operacional
    status
  end

  def equipe_apoio
    support_team
  end

  def ultimo_andamento
    last_movement
  end

  def data_ultimo_andamento
    last_movement_at
  end

  def proxima_providencia
    next_action
  end

  def proximo_prazo
    next_deadline_on
  end

  def observacoes_estrategicas
    strategic_notes
  end

  private

  def normalize_legacy_phase_and_status
    phase_map = {
      "intake" => "atendimento_inicial",
      "analysis" => "analise_juridica",
      "filing" => "judicial",
      "instruction" => "instrucao",
      "judgment" => "sentenca",
      "appeal" => "recurso",
      "enforcement" => "cumprimento_execucao",
      "closed" => "encerrado"
    }

    status_map = {
      "active" => "ativo",
      "on_hold" => "suspenso",
      "completed" => "encerrado",
      "archived" => "arquivado"
    }

    self.phase = phase_map[phase] || phase
    self.status = status_map[status] || status
  end
end
