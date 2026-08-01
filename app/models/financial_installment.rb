class FinancialInstallment < ApplicationRecord
  belongs_to :financial_contract, inverse_of: :installments
  has_one :payment, class_name: "FinancialPayment", dependent: :destroy, inverse_of: :financial_installment

  enum :status, {
    pending: "pending",
    paid: "paid"
  }, prefix: true, validate: true

  validates :number,
    numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 },
    uniqueness: { scope: :financial_contract_id }
  validates :due_date, presence: true
  validates :amount, numericality: { greater_than: 0 }

  def register_payment!(amount:, paid_at:, payment_method:, recorded_by:, proof:)
    requested_amount = amount.to_d
    raise ArgumentError, "payment amount must equal installment amount" unless requested_amount == self.amount

    with_lock do
      raise ArgumentError, "installment already paid" if payment.present? || status_paid?

      transaction do
        registered_payment = build_payment(
          amount: requested_amount,
          paid_at: paid_at,
          payment_method: payment_method,
          recorded_by: recorded_by
        )
        registered_payment.proof.attach(proof) if proof.present?
        registered_payment.save!
        update!(status: "paid")
        registered_payment
      end
    end
  end
end
