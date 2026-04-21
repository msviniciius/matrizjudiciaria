class Deadline < ApplicationRecord
  belongs_to :legal_case

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

  validates :title, :due_date, :status, presence: true
  validates :status, inclusion: { in: statuses.keys }
  validates :priority, inclusion: { in: priorities.keys }, allow_blank: true
  validates :deadline_type, inclusion: { in: deadline_types.keys }, allow_blank: true
  validate :start_date_cannot_be_after_due_date

  before_validation :apply_default_deadline_setting, on: :create

  private

  def start_date_cannot_be_after_due_date
    return if start_date.blank? || due_date.blank?
    return unless start_date > due_date

    errors.add(:start_date, "não pode ser maior que a data final")
  end

  def apply_default_deadline_setting
    return if legal_case.blank? || deadline_type.blank?

    setting = legal_case.office&.deadline_settings&.active&.find_by(deadline_type: deadline_type)
    return if setting.blank?

    self.due_date ||= Date.current + setting.days_to_due.days
    self.priority ||= setting.default_priority if setting.default_priority.present?
  end
end
