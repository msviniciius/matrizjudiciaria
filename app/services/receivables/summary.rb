class Receivables::Summary
  INACTIVE_STATUSES = %w[awaiting_trigger canceled].freeze
  CLOSED_STATUSES = (INACTIVE_STATUSES + [ "received" ]).freeze

  def initialize(scope:, reference_date: Date.current)
    @scope = scope
    @reference_date = reference_date
  end

  def call
    {
      expected: active_scope.sum(:amount),
      received: payment_scope.sum(:amount_paid),
      open_balance: sum_balance(open_scope),
      overdue: sum_balance(open_scope.where("due_date < ?", reference_date)),
      partial: partial_payment_scope.sum(:amount_paid),
      upcoming: sum_balance(open_scope.where(due_date: upcoming_period)),
      received_by_day: received_scope.group(:paid_at).sum(:amount_paid)
    }
  end

  private

  attr_reader :scope, :reference_date

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
