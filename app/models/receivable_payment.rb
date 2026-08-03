class ReceivablePayment < ApplicationRecord
  belongs_to :receivable
  belongs_to :recorded_by, class_name: "User", optional: true

  validates :amount, numericality: { greater_than: 0 }
  validates :paid_at, presence: true
end
