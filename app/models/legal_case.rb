class LegalCase < ApplicationRecord
  attr_accessor :skip_quality_validation
  INTERNAL_NUMBER_PREFIX = "SEI"
  INTERNAL_NUMBER_MIN_DIGITS = 2
  INTERNAL_NUMBER_START = 1
  CALENDAR_FEED_PURPOSE = :google_calendar_feed
  AUTO_SYNC_DEADLINE_TITLE = "Prazo do processo"

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
  belongs_to :office
  belongs_to :unit, optional: true
  belongs_to :legal_area, optional: true
  belongs_to :process_type, optional: true
  belongs_to :court, optional: true
  belongs_to :district, optional: true

  has_many :case_events, dependent: :destroy
  has_many :process_movements, foreign_key: :process_id, dependent: :destroy
  has_many :deadlines, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :process_exams, dependent: :destroy
  accepts_nested_attributes_for :process_exams,
    reject_if: :process_exam_attributes_blank?,
    allow_destroy: true

  enum :status, OFFICIAL_STATUSES.index_with(&:itself), prefix: true

  enum :priority, {
    low: "low",
    medium: "medium",
    high: "high",
    urgent: "urgent"
  }, prefix: true

  enum :phase, OFFICIAL_PHASES.index_with(&:itself), prefix: true

  before_validation :normalize_legacy_phase_and_status
  before_validation :apply_office_operational_defaults
  before_validation :assign_internal_number, on: :create
  after_save :sync_next_deadline_to_deadlines, if: :saved_change_to_next_deadline_on?

  validates :internal_number, :legal_area_id, :process_type_id, :status, presence: true
  validates :internal_number, uniqueness: { scope: :office_id }
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
  scope :syncable, -> { operational.where.not(external_number: [ nil, "" ]) }
  scope :needing_sync, -> { syncable.where("last_synced_at IS NULL OR last_synced_at < ?", 1.hour.ago) }
  scope :with_pje_case, ->(pje_id) { where(pje_case_id: pje_id) }
  scope :with_new_imported_events, -> {
    syncable
      .joins(:case_events)
      .where(case_events: { entry_kind: "andamento" })
      .where.not(case_events: { pje_external_id: nil })
      .where("case_events.created_at > COALESCE(legal_cases.last_viewed_events_at, ?)", 1.week.ago)
      .distinct
  }

  def has_new_imported_events?
    case_events
      .where(entry_kind: "andamento")
      .where.not(pje_external_id: nil)
      .where("case_events.created_at > ?", last_viewed_events_at || 1.week.ago)
      .exists?
  end

  def self.with_pending_requirement
    joins(:process_movements)
      .where(process_movements: { administrative_situation: "em_exigencia", active: true })
      .distinct
  end

  def self.next_internal_number_preview(office = nil)
    scope = office.present? ? where(office_id: office.id) : all

    latest = scope.where("internal_number ~ ?", "^#{INTERNAL_NUMBER_PREFIX}[0-9]+$")
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
      .order(created_at: :desc, id: :desc)
      .first

    attrs = {
      last_movement: latest_movement&.description,
      last_movement_at: latest_movement&.created_at,
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

  def health_calculator
    @health_calculator ||= LegalCaseHealthCalculator.new(self)
  end

  delegate :score, :status, :issues, to: :health_calculator, prefix: :health

  def health_status
    health_calculator.status
  end

  def health_status_verde?
    health_calculator.verde?
  end

  def health_status_amarelo?
    health_calculator.amarelo?
  end

  def health_status_vermelho?
    health_calculator.vermelho?
  end

  def pericia_alerta?
    process_exams.where(status: [ "designada", "redesignada", "laudo_pendente" ], active: true).exists?
  end

  def display_number_and_client
    "#{internal_number} - #{client&.full_name.presence || 'Cliente não informado'}"
  end

  def next_deadline_required?
    next_deadline_expected?
  end

  def next_action_warning?
    operational_tracking_required? && next_action.blank?
  end

  def calendar_feed_token(expires_in: 5.years)
    signed_id(purpose: CALENDAR_FEED_PURPOSE, expires_in: expires_in)
  end

  def self.find_by_calendar_feed_token!(token)
    find_signed!(token, purpose: CALENDAR_FEED_PURPOSE)
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

    operational_tracking_required?
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

  def process_exam_attributes_blank?(attrs)
    values = attrs.to_h.with_indifferent_access.values_at(
      :exam_nature, :exam_scope, :status, :scheduled_at, :location, :expert_name, :notes
    )
    values.all?(&:blank?)
  end

  def assign_internal_number
    return if internal_number.present?
    self.internal_number = self.class.next_internal_number_preview(office)
  end

  def apply_office_operational_defaults
    return if office.blank?

    self.phase = office.default_phase if phase.blank?
    self.status = office.default_status if status.blank?
    self.priority = office.default_priority if priority.blank?
  end

  def sync_next_deadline_to_deadlines
    synced_deadline = deadlines.find_by(title: AUTO_SYNC_DEADLINE_TITLE, deadline_type: "internal")

    if next_deadline_on.blank?
      synced_deadline&.destroy
      return
    end

    synced_deadline ||= deadlines.build(
      title: AUTO_SYNC_DEADLINE_TITLE,
      deadline_type: "internal"
    )

    synced_deadline.due_date = next_deadline_on
    synced_deadline.status = "pending" if synced_deadline.status.blank?
    synced_deadline.priority = "medium" if synced_deadline.priority.blank?
    synced_deadline.responsible_name = responsible_name.presence || synced_deadline.responsible_name
    synced_deadline.save! if synced_deadline.changed?
  end
end
