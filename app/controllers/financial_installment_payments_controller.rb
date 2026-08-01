class FinancialInstallmentPaymentsController < ApplicationController
  before_action :set_legal_case
  before_action :require_recording_user!

  def create
    installment = @legal_case.financial_contract&.installments&.find(params.expect(:financial_installment_id))
    return render json: { error: "financial installment was not found" }, status: :not_found unless installment

    installment.register_payment!(
      amount: installment.amount,
      paid_at: parsed_paid_at,
      payment_method: payment_params[:payment_method],
      recorded_by: current_user,
      proof: payment_params[:proof]
    )

    render json: snapshot
  rescue ActiveRecord::RecordNotFound
    render json: { error: "financial installment was not found" }, status: :not_found
  rescue ActiveRecord::RecordInvalid, ArgumentError => error
    render json: { error: error.message }, status: :unprocessable_entity
  end

  private

  def set_legal_case
    @legal_case = scope_by_current_unit(current_office.legal_cases).find(params.expect(:legal_case_id))
  end

  def require_recording_user!
    return if current_user.present?

    render json: { error: "authentication required" }, status: :unauthorized
  end

  def payment_params
    params.expect(payment: [ :paid_at, :payment_method, :proof ])
  end

  def parsed_paid_at
    value = payment_params[:paid_at]
    raise ArgumentError, "payment date is required" if value.blank?

    Time.zone.parse(value.to_s)
  rescue ArgumentError
    raise ArgumentError, "payment date must be valid"
  end

  def snapshot
    LegalCaseShowSnapshot.new(legal_case: @legal_case.reload, current_user: current_user).as_json
  end
end
