class FinancialContractsController < ApplicationController
  before_action :set_legal_case

  def create
    return render_contract_exists if @legal_case.financial_contract.present?

    @financial_contract = FinancialContract.new(office: current_office, legal_case: @legal_case)
    persist_contract!
  end

  def update
    @financial_contract = @legal_case.financial_contract
    return render_contract_missing if @financial_contract.blank?

    persist_contract!
  end

  private

  def set_legal_case
    @legal_case = scope_by_current_unit(current_office.legal_cases).find(params.expect(:legal_case_id))
  end

  def persist_contract!
    attributes = normalized_contract_attributes
    first_due_date = resolve_first_due_date(attributes.delete(:first_due_date))
    installment_count = attributes.fetch(:installment_count)
    installments = attributes.delete(:installments)
    document = attributes.delete(:contract_document)
    total_amount = FinancialContracts::Calculator.call(
      fixed_amount: attributes[:fixed_amount],
      includes_percentage: attributes[:includes_percentage],
      percentage: attributes[:percentage],
      percentage_basis: attributes[:percentage_basis],
      claim_value: @legal_case.claim_value,
      client_received: attributes[:client_received_amount]
    )

    FinancialContract.transaction do
      reject_paid_installment_rebuild!
      @financial_contract.assign_attributes(attributes.merge(total_amount: total_amount))
      @financial_contract.save!
      @financial_contract.contract_document.attach(document) if document.present?
      @financial_contract.installments.destroy_all
      FinancialContracts::InstallmentBuilder.call(
        contract: @financial_contract,
        count: installment_count,
        first_due_date: first_due_date,
        installments: installments
      )
    end

    render json: snapshot
  rescue ActiveRecord::RecordInvalid => error
    render json: { errors: error.record.errors }, status: :unprocessable_entity
  rescue ArgumentError => error
    render json: { error: error.message }, status: :unprocessable_entity
  end

  def financial_contract_params
    params.expect(financial_contract: [
      :fixed_amount,
      :includes_percentage,
      :percentage,
      :percentage_basis,
      :client_received_amount,
      :installment_count,
      :first_due_date,
      :contract_document,
      installments: [ [ :number, :amount, :due_date ] ]
    ])
  end

  def normalized_contract_attributes
    attributes = financial_contract_params.to_h.symbolize_keys
    attributes[:includes_percentage] = ActiveModel::Type::Boolean.new.cast(attributes[:includes_percentage])
    attributes[:percentage] = nil unless attributes[:includes_percentage]
    attributes[:percentage_basis] = nil unless attributes[:includes_percentage]
    attributes[:client_received_amount] = nil unless attributes[:percentage_basis] == "client_received"
    attributes
  end

  def resolve_first_due_date(value)
    return parse_first_due_date(value) if value.present?

    existing_due_date = @financial_contract.installments.first&.due_date if @financial_contract.persisted?
    return existing_due_date if existing_due_date.present?

    raise ArgumentError, "first due date is required"
  end

  def parse_first_due_date(value)
    Date.iso8601(value.to_s)
  rescue ArgumentError
    raise ArgumentError, "first due date must be a valid date"
  end

  def reject_paid_installment_rebuild!
    return unless @financial_contract.persisted?
    return unless @financial_contract.installments.where(status: "paid").exists?

    raise ArgumentError, "a financial contract with paid installments cannot be recalculated"
  end

  def snapshot
    LegalCaseShowSnapshot.new(legal_case: @legal_case.reload, current_user: current_user).as_json
  end

  def render_contract_exists
    render json: { error: "financial contract already exists for this legal case" }, status: :unprocessable_entity
  end

  def render_contract_missing
    render json: { error: "financial contract was not found for this legal case" }, status: :not_found
  end
end
