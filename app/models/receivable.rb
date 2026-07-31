class Receivable < ApplicationRecord
  OPEN_STATUSES = %w[pending partial overdue].freeze

  belongs_to :office
  belongs_to :unit, optional: true
  belongs_to :client, optional: true
  belongs_to :legal_case, optional: true

  enum :status, {
    awaiting_trigger: "awaiting_trigger",
    pending: "pending",
    partial: "partial",
    received: "received",
    overdue: "overdue",
    canceled: "canceled"
  }, prefix: true

  enum :trigger, {
    manual: "manual",
    case_started: "case_started",
    case_won: "case_won"
  }, prefix: true

  validates :description, :status, :trigger, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :amount_paid, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: :amount }
  validate :unit_belongs_to_same_office, if: -> { unit.present? && office.present? }
  validate :client_belongs_to_same_office, if: -> { client.present? && office.present? }
  validate :legal_case_belongs_to_same_office, if: -> { legal_case.present? && office.present? }

  scope :for_period, ->(period) { where(due_date: period) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_unit, ->(unit) { where(unit: unit) }

  def balance
    amount - amount_paid
  end

  def overdue?
    due_date.present? && due_date < Date.current && OPEN_STATUSES.include?(status)
  end

  def activate!
    self.status = "pending"
    self.triggered_at = Time.current
    save!
  end

  def register_payment!(value:, paid_at: Date.current, payment_method: nil)
    self.amount_paid = amount_paid + value
    self.paid_at = paid_at if amount_paid >= amount
    self.status = amount_paid.zero? ? "pending" : (amount_paid >= amount ? "received" : "partial")
    self.payment_method = payment_method if payment_method.present?
    save!
  end

  private

  def unit_belongs_to_same_office
    return if unit.office_id == office_id

    errors.add(:unit_id, "não pertence ao escritório atual")
  end

  def client_belongs_to_same_office
    return if client.office_id == office_id

    errors.add(:client_id, "não pertence ao escritório atual")
  end

  def legal_case_belongs_to_same_office
    return if legal_case.office_id == office_id

    errors.add(:legal_case_id, "não pertence ao escritório atual")
  end
end
