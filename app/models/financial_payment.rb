class FinancialPayment < ApplicationRecord
  belongs_to :financial_installment, inverse_of: :payment
  belongs_to :recorded_by, class_name: "User"

  has_one_attached :proof

  enum :payment_method, {
    pix: "pix",
    cash: "cash",
    credit_card: "credit_card",
    debit_card: "debit_card"
  }, prefix: true, validate: true

  validates :financial_installment_id, uniqueness: true
  validates :amount, numericality: { greater_than: 0 }
  validates :paid_at, presence: true
  validate :amount_matches_installment
  validate :recording_user_belongs_to_same_office
  validate :proof_must_be_attached

  private

  def amount_matches_installment
    return if financial_installment.blank? || amount.blank?
    return if amount == financial_installment.amount

    errors.add(:amount, "deve corresponder ao valor integral da parcela")
  end

  def recording_user_belongs_to_same_office
    return if recorded_by.blank? || financial_installment.blank?
    return if recorded_by.office_id == financial_installment.financial_contract.office_id

    errors.add(:recorded_by, "não pertence ao escritório atual")
  end

  def proof_must_be_attached
    return if proof.attached? || attachment_changes&.key?("proof")

    errors.add(:proof, "deve ser anexado")
  end
end
