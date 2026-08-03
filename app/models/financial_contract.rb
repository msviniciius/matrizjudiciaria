class FinancialContract < ApplicationRecord
  before_validation :default_includes_percentage

  belongs_to :office
  belongs_to :legal_case

  has_many :installments,
    -> { order(:number) },
    class_name: "FinancialInstallment",
    dependent: :destroy,
    inverse_of: :financial_contract

  has_one_attached :contract_document

  enum :percentage_basis, {
    claim_value: "claim_value",
    client_received: "client_received"
  }, prefix: true, validate: { allow_nil: true }

  validates :legal_case_id, uniqueness: true
  validates :fixed_amount, :total_amount, numericality: { greater_than: 0 }
  validates :includes_percentage, inclusion: { in: [ true, false ] }
  validates :installment_count,
    numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }
  validates :percentage,
    numericality: { greater_than: 0, less_than_or_equal_to: 100 },
    allow_nil: true
  validates :client_received_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :legal_case_belongs_to_same_office
  validate :percentage_configuration

  private

  def default_includes_percentage
    self.includes_percentage = false if includes_percentage.nil?
  end

  def legal_case_belongs_to_same_office
    return if legal_case.blank? || office.blank? || legal_case.office_id == office_id

    errors.add(:legal_case_id, "não pertence ao escritório atual")
  end

  def percentage_configuration
    if includes_percentage?
      errors.add(:percentage, :blank) if percentage.blank?
      errors.add(:percentage_basis, :blank) if percentage_basis.blank?
    else
      errors.add(:percentage, "deve ficar em branco para honorários somente fixos") if percentage.present?
      if percentage_basis.present?
        errors.add(:percentage_basis, "deve ficar em branco para honorários somente fixos")
      end
    end
  end
end
