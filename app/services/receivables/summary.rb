class Receivables::Summary
  INACTIVE_STATUSES = %w[awaiting_trigger canceled].freeze
  CLOSED_STATUSES = (INACTIVE_STATUSES + [ "received" ]).freeze

  def initialize(scope:, financial_scope: nil, reference_date: Date.current)
    @scope = scope
    @financial_scope = financial_scope
    @reference_date = reference_date
  end

  def call
    {
      expected: active_scope.sum(:amount) + financial_expected,
      received: payment_scope.sum(:amount_paid) + financial_received,
      open_balance: sum_balance(open_scope) + financial_open_balance,
      overdue: sum_balance(open_scope.where("due_date < ?", reference_date)) + financial_overdue,
      partial: partial_payment_scope.sum(:amount_paid),
      upcoming: sum_balance(open_scope.where(due_date: upcoming_period)) + financial_upcoming,
      received_by_day: received_scope.group(:paid_at).sum(:amount_paid).merge(financial_received_by_day) { |_day, legacy, hybrid| legacy + hybrid }
    }
  end

  private

  attr_reader :scope, :financial_scope, :reference_date

  def financial_expected
    financial_scope ? financial_scope.sum(:amount) : 0.to_d
  end

  def financial_received
    return 0.to_d unless financial_scope

    financial_scope.joins(:payment).sum("financial_payments.amount")
  end

  def financial_open_balance
    return 0.to_d unless financial_scope

    financial_scope.where(status: "pending").sum(:amount)
  end

  def financial_overdue
    return 0.to_d unless financial_scope

    financial_scope.where(status: "pending").where("due_date < ?", reference_date).sum(:amount)
  end

  def financial_upcoming
    return 0.to_d unless financial_scope

    financial_scope.where(status: "pending", due_date: upcoming_period).sum(:amount)
  end

  def financial_received_by_day
    return {} unless financial_scope

    financial_scope.joins(:payment).group(Arel.sql("DATE(financial_payments.paid_at)")).sum("financial_payments.amount")
  end

  def base_scope
    scope.except(:order)
  end

  def active_scope
    base_scope.where.not(status: INACTIVE_STATUSES)
  end

  def open_scope
    base_scope.where.not(status: CLOSED_STATUSES)
  end

  def received_scope
    payment_scope.where.not(paid_at: nil)
  end

  def payment_scope
    base_scope.where.not(status: "awaiting_trigger")
  end

  def partial_payment_scope
    base_scope.where(status: "partial").or(base_scope.where(status: "canceled").where("amount_paid > 0"))
  end

  def upcoming_period
    (reference_date + 1.day)..(reference_date + 30.days)
  end

  def sum_balance(relation)
    relation.sum("amount - amount_paid")
  end
end
