class Deadline < ApplicationRecord
  belongs_to :legal_case
  belongs_to :expediente, optional: true

  enum :status, {
    pending: "pending",
    in_progress: "in_progress",
    completed: "completed",
    overdue: "overdue",
    suspended: "suspended",
    extended: "extended"
  }, prefix: true

  enum :priority, {
    low: "low",
    medium: "medium",
    high: "high",
    urgent: "urgent"
  }, prefix: true

  enum :deadline_type, {
    judicial: "judicial",
    administrative: "administrative",
    internal: "internal",
    hearing: "hearing",
    expert_exam: "expert_exam",
    appeal: "appeal",
    manifestation: "manifestation",
    compliance: "compliance",
    documentary: "documentary",
    contractual: "contractual"
  }, prefix: true

  validates :title, :status, presence: true
  validates :due_date, presence: true, unless: :awaiting_expediente_ciencia?
  validates :status, inclusion: { in: statuses.keys }
  validates :priority, inclusion: { in: priorities.keys }, allow_blank: true
  validates :deadline_type, inclusion: { in: deadline_types.keys }, allow_blank: true
  validates :expediente, uniqueness: true, allow_nil: true
  validate :expediente_legal_case_matches
  validate :start_date_cannot_be_after_due_date

  before_validation :apply_default_deadline_setting, on: :create

  def cumprir!(protocolo_ref: nil)
    attributes = { status: :completed, completed_at: completed_at || Time.current }
    attributes[:protocolo_ref] = protocolo_ref if expediente.present? && protocolo_ref.present?
    update!(attributes)
  end

  private

  def awaiting_expediente_ciencia?
    expediente.present? && status_pending?
  end

  def expediente_legal_case_matches
    return if expediente.blank? || legal_case_id.blank? || expediente.legal_case_id == legal_case_id

    errors.add(:legal_case, "deve ser o mesmo processo do expediente")
  end

  def start_date_cannot_be_after_due_date
    return if start_date.blank? || due_date.blank?
    return unless start_date > due_date

    errors.add(:start_date, "não pode ser maior que a data final")
  end

  def apply_default_deadline_setting
    return if legal_case.blank? || deadline_type.blank?
    return if expediente.present? && deadline_type_judicial? && status_pending? && due_date.blank?

    setting = legal_case.office&.deadline_settings&.active&.find_by(deadline_type: deadline_type)
    return if setting.blank?

    self.due_date ||= Date.current + setting.days_to_due.days
    self.priority ||= setting.default_priority if setting.default_priority.present?
  end
end
