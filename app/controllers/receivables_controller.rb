class ReceivablesController < ApplicationController
  before_action :require_admin!
  before_action :set_receivable, only: %i[edit update destroy register_payment cancel]
  before_action :load_form_collections, only: %i[new edit]

  def index
    @receivables = Receivables::Query.new(office: current_office, params: params).call
    @summary = Receivables::Summary.new(scope: @receivables, reference_date: Date.current).call
    load_filter_collections
  end

  def new
    @receivable = current_office.receivables.new
  end

  def create
    @receivable = current_office.receivables.new(receivable_params)

    if @receivable.save
      redirect_to receivables_path, notice: "Conta a receber cadastrada com sucesso."
    else
      load_form_collections
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @receivable.update(receivable_params)
      redirect_to receivables_path, notice: "Conta a receber atualizada com sucesso.", status: :see_other
    else
      load_form_collections
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

  def load_filter_collections
    @units = current_office.units.order(:name)
    @clients = current_office.clients.order(:full_name)
    @legal_cases = current_office.legal_cases.order(:internal_number)
  end

  alias_method :load_form_collections, :load_filter_collections
end
