class Receivables::Query
  DEFAULT_PERIOD_LENGTH = 30.days

  def initialize(office:, params:)
    @office = office
    @params = params
  end

  def call
    scope = office.receivables.for_period(period)
    scope = filter_unit(scope)
    scope = filter(scope, :client_id)
    scope = filter(scope, :legal_case_id)
    scope = filter_status(scope)

    scope.order(:due_date, :id)
  end

  # Parcelas do novo contrato financeiro são expostas separadamente para que
  # os consumidores legados continuem recebendo uma relação de Receivable.
  def financial_installments
    scope = FinancialInstallment
      .joins(financial_contract: :legal_case)
      .where(financial_contracts: { office_id: office.id })
      .where(due_date: period)

    scope = filter_financial_unit(scope)
    scope = scope.where(financial_contracts: { legal_case_id: value_for(:legal_case_id) }) if value_for(:legal_case_id).present?
    scope = scope.where(legal_cases: { client_id: value_for(:client_id) }) if value_for(:client_id).present?
    filter_financial_status(scope)
  end

  private

  attr_reader :office, :params

  def period
    supplied_period = value_for(:period)
    return default_period if supplied_period.blank?

    normalize_period(supplied_period) || default_period
  end

  def default_period
    (Date.current - (DEFAULT_PERIOD_LENGTH - 1.day))..Date.current
  end

  def normalize_period(supplied_period)
    return supplied_period if supplied_period.is_a?(Range)

    if supplied_period.respond_to?(:[]) && !supplied_period.is_a?(String)
      start_date = parse_date(period_value(supplied_period, :start, :from))
      end_date = parse_date(period_value(supplied_period, :end, :to))
      return start_date..end_date if start_date && end_date
    end

    start_date, end_date = supplied_period.to_s.split("..", 2).map { |date| parse_date(date) }
    return start_date..end_date if start_date && end_date

    date = parse_date(supplied_period)
    date..date if date
  end

  def parse_date(value)
    return value if value.is_a?(Date)

    Date.iso8601(value.to_s)
  rescue ArgumentError
    nil
  end

  def period_value(supplied_period, *keys)
    keys.each do |key|
      value = supplied_period[key] || supplied_period[key.to_s]
      return value if value.present?
    end
    nil
  end

  def filter_unit(scope)
    unit_id = value_for(:unit_id)
    return scope if unit_id.blank?

    unit = office.units.find_by(id: unit_id)
    return scope.none if unit.blank?

    scope.by_unit(unit)
  end

  def filter(scope, key)
    value = value_for(key)
    return scope if value.blank?

    scope.where(key => value)
  end

  def filter_status(scope)
    status = value_for(:status)
    return scope if status.blank?
    return overdue_scope(scope) if status == "overdue"

    scope.where(status: status)
  end

  def filter_financial_unit(scope)
    unit_id = value_for(:unit_id)
    return scope if unit_id.blank?

    unit = office.units.find_by(id: unit_id)
    return scope.none if unit.blank?

    scope.where(legal_cases: { unit_id: unit.id })
  end

  def filter_financial_status(scope)
    status = value_for(:status)
    return scope if status.blank?

    case status
    when "received"
      scope.where(status: "paid")
    when "overdue"
      scope.where(status: "pending").where("due_date < ?", Date.current)
    when "pending"
      scope.where(status: "pending").where("due_date >= ? OR due_date IS NULL", Date.current)
    when "partial", "canceled", "awaiting_trigger"
      scope.none
    else
      scope.none
    end
  end

  def overdue_scope(scope)
    scope.where(status: Receivable::OPEN_STATUSES).where("due_date < ?", Date.current)
  end

  def value_for(key)
    params[key] || params[key.to_s]
  end
end
