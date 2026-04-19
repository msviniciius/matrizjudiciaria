class LegalCase < ApplicationRecord
  attr_accessor :skip_quality_validation
  INTERNAL_NUMBER_PREFIX = "SEI"
  INTERNAL_NUMBER_MIN_DIGITS = 2
  INTERNAL_NUMBER_START = 1

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
    em_analise
    aguardando_providencia_escritorio
    aguardando_cliente
    aguardando_terceiros
    suspenso
    deferido
    indeferido
    arquivado
    encerrado
  ].freeze

  OPERATIONAL_STATUSES = %w[
    em_analise
    aguardando_providencia_escritorio
    aguardando_cliente
    aguardando_terceiros
    suspenso
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
  before_validation :assign_internal_number, on: :create

  validates :internal_number, :legal_area_id, :process_type_id, :phase, :status, presence: true
  validates :internal_number, uniqueness: true
  validates :status, inclusion: { in: statuses.keys }
  validates :priority, inclusion: { in: priorities.keys }, allow_blank: true
  validates :phase, inclusion: { in: phases.keys }
  validate :validate_operational_snapshot_quality

  scope :with_upcoming_deadline, ->(days = 7) { where(next_deadline_on: Date.current..(Date.current + days.to_i.days)) }
  scope :without_deadline, -> { where(next_deadline_on: nil) }
  scope :with_pericia, -> { where(tem_pericia: true) }
  scope :operational, -> { where.not(status: [ "arquivado", "encerrado", "deferido", "indeferido" ]).where.not(phase: "encerrado") }
  scope :deadline_due_today, -> { where(next_deadline_on: Date.current) }
  scope :deadline_due_in_48h, -> { where(next_deadline_on: (Date.current + 1.day)..(Date.current + 2.days)) }
  scope :deadline_overdue, -> { where("next_deadline_on < ?", Date.current) }
  scope :without_next_action, -> { where("TRIM(COALESCE(next_action, '')) = ''") }

  def self.with_pending_requirement
    joins(:process_movements)
      .where(process_movements: { administrative_situation: "em_exigencia", active: true })
      .distinct
  end

  def self.next_internal_number_preview
    latest = where("internal_number ~ ?", "^#{INTERNAL_NUMBER_PREFIX}[0-9]+$")
      .maximum(Arel.sql("CAST(SUBSTRING(internal_number FROM 4) AS bigint)"))
      .to_i

    next_sequence = [ latest + 1, INTERNAL_NUMBER_START ].max
    "#{INTERNAL_NUMBER_PREFIX}#{next_sequence.to_s.rjust(INTERNAL_NUMBER_MIN_DIGITS, '0')}"
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

    unified_phase = event.phase_after_unified
    unified_status = event.status_after_unified

    attrs[:phase] = unified_phase if unified_phase.present? && self.class.phases.key?(unified_phase)
    attrs[:status] = unified_status if unified_status.present? && self.class.statuses.key?(unified_status)

    self.skip_quality_validation = true
    update!(attrs.compact)
  ensure
    self.skip_quality_validation = false
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

    self.skip_quality_validation = true
    update!(attrs.compact)
  ensure
    self.skip_quality_validation = false
  end

  def prazo_alerta?
    next_deadline_on.present? && next_deadline_on <= Date.current + 7.days
  end

  def deadline_overdue?
    next_deadline_on.present? && next_deadline_on < Date.current
  end

  def stale_last_movement?
    last_movement_at.blank? || last_movement_at < 15.days.ago
  end

  def health_score
    score = 100
    score -= 45 if deadline_overdue?
    score -= 20 if next_deadline_expected? && next_deadline_on.blank?
    score -= 18 if next_action.blank?
    score -= 12 if responsible_name.blank?
    score -= 10 if stale_last_movement?
    score -= 8 if prazo_alerta? && !deadline_overdue?
    score.clamp(0, 100)
  end

  def health_status
    case health_score
    when 80..100 then "verde"
    when 50..79 then "amarelo"
    else "vermelho"
    end
  end

  def health_status_verde?
    health_status == "verde"
  end

  def health_status_amarelo?
    health_status == "amarelo"
  end

  def health_status_vermelho?
    health_status == "vermelho"
  end

  def health_issues
    issues = []
    issues << "Prazo vencido" if deadline_overdue?
    issues << "Sem próxima providência" if next_action.blank?
    issues << "Sem próximo prazo definido" if next_deadline_expected? && next_deadline_on.blank?
    issues << "Sem responsável definido" if responsible_name.blank?
    issues << "Sem atualização recente" if stale_last_movement?
    issues
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

  def next_deadline_required?
    next_deadline_expected?
  end

  def next_action_warning?
    operational_tracking_required? && next_action.blank?
  end

  def observacoes_estrategicas
    strategic_notes
  end

  private

  def operational_tracking_required?
    return false if status_arquivado? || status_encerrado? || phase_encerrado?

    OPERATIONAL_STATUSES.include?(status.to_s)
  end

  def next_deadline_expected?
    %w[
      em_analise
      aguardando_providencia_escritorio
      aguardando_cliente
      aguardando_terceiros
    ].include?(status.to_s)
  end

  def validate_operational_snapshot_quality
    return if skip_quality_validation
    return unless operational_tracking_required?

    errors.add(:responsible_name, :blank) if responsible_name.blank?
    return unless next_deadline_expected? && next_deadline_on.blank?

    errors.add(:next_deadline_on, "deve ser informado para o acompanhamento operacional")
  end

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
      "active" => "em_analise",
      "ativo" => "em_analise",
      "on_hold" => "suspenso",
      "completed" => "encerrado",
      "archived" => "arquivado"
    }

    self.phase = phase_map[phase] || phase
    self.status = status_map[status] || status
  end

  def assign_internal_number
    return if internal_number.present?
    self.internal_number = self.class.next_internal_number_preview
  end
end
