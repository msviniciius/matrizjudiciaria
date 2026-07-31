class ReceivablesController < ApplicationController
  before_action :require_admin!
  before_action :set_receivable, only: %i[edit update destroy register_payment cancel]

  def index
    @receivables = Receivables::Query.new(office: current_office, params: params).call
  end

  def new
    @receivable = current_office.receivables.new
  end

  def create
    @receivable = current_office.receivables.new(receivable_params)

    if @receivable.save
      redirect_to receivables_path, notice: "Conta a receber cadastrada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @receivable.update(receivable_params)
      redirect_to receivables_path, notice: "Conta a receber atualizada com sucesso.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @receivable.destroy!
    redirect_to receivables_path, notice: "Conta a receber excluída com sucesso.", status: :see_other
  end

  def register_payment
    @receivable.register_payment!(
      value: payment_params[:value].to_d,
      paid_at: payment_params[:paid_at].presence || Date.current,
      payment_method: payment_params[:payment_method]
    )

    redirect_to receivables_path, notice: "Recebimento registrado com sucesso.", status: :see_other
  rescue ArgumentError, ActiveRecord::RecordInvalid => error
    redirect_to receivables_path, alert: error.message, status: :see_other
  end

  def cancel
    @receivable.update!(status: "canceled")
    redirect_to receivables_path, notice: "Conta a receber cancelada com sucesso.", status: :see_other
  end

  private

  def set_receivable
    @receivable = current_office.receivables.find(params.expect(:id))
  end

  def receivable_params
    params.expect(receivable: [
      :description,
      :amount,
      :due_date,
      :payment_method,
      :notes,
      :trigger,
      :unit_id,
      :client_id,
      :legal_case_id
    ])
  end

  def payment_params
    params.expect(payment: [ :value, :paid_at, :payment_method ])
  end
end
