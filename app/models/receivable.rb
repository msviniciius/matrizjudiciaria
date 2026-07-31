class Receivable < ApplicationRecord
  OPEN_STATUSES = %w[pending partial overdue].freeze

  belongs_to :office
  belongs_to :unit, optional: true
  belongs_to :client, optional: true
  belongs_to :legal_case, optional: true
  belongs_to :payment_recorded_by, class_name: "User", optional: true
  belongs_to :canceled_by, class_name: "User", optional: true
  has_many :receivable_payments, dependent: :destroy

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
  validate :legal_case_links_match

  before_validation :apply_trigger_state
  validate :received_status_requires_full_payment

  scope :for_period, ->(period) { where(due_date: period).or(where(due_date: nil)) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_unit, ->(unit) { where(unit: unit) }
  scope :awaiting_case_won_trigger, -> { where(trigger: "case_won", status: "awaiting_trigger") }

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

  def register_payment!(value:, paid_at: Date.current, payment_method: nil, recorded_by: nil)
    raise ArgumentError, "payment value must be greater than zero" unless value > 0
    raise ArgumentError, "canceled receivables cannot receive payments" if status_canceled?

    transaction do
      self.amount_paid = amount_paid + value
      self.paid_at = paid_at if amount_paid >= amount
      self.status = amount_paid.zero? ? "pending" : (amount_paid >= amount ? "received" : "partial")
      self.payment_method = payment_method if payment_method.present?
      self.payment_recorded_by = recorded_by if recorded_by.present?
      self.payment_recorded_at = Time.current
      save!
      receivable_payments.create!(amount: value, paid_at: paid_at, payment_method: payment_method, recorded_by: recorded_by)
    end
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

  def received_status_requires_full_payment
    return unless status_received?
    return if amount.present? && amount_paid == amount

    errors.add(:status, "só pode ser recebida quando estiver totalmente quitada")
  end

  def legal_case_links_match
    return unless legal_case.present?

    errors.add(:client_id, "deve corresponder ao cliente do processo") if client_id != legal_case.client_id
    errors.add(:unit_id, "deve corresponder à unidade do processo") if unit_id != legal_case.unit_id
  end

  def apply_trigger_state
    if trigger_case_won?
      if legal_case&.outcome_won? && (new_record? || status_awaiting_trigger?)
        self.status = "pending"
        self.triggered_at ||= Time.current
      elsif new_record?
        self.status = "awaiting_trigger"
        self.triggered_at = nil
      end
    elsif trigger_case_started?
      self.status = "pending"
      self.triggered_at ||= Time.current
    end
  end
end
