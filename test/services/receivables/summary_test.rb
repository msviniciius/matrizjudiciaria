require "test_helper"

class Receivables::SummaryTest < ActiveSupport::TestCase
  test "summarizes active receivables and ignores canceled or untriggered accounts" do
    reference_date = Date.new(2026, 7, 31)
    due_today = create_receivable(amount: 1_000, due_date: reference_date)
    partial = create_receivable(amount: 500, amount_paid: 200, status: "partial", due_date: reference_date - 1.day)
    received = create_receivable(amount: 800, amount_paid: 800, status: "received", due_date: reference_date - 2.days, paid_at: reference_date - 1.day)
    overdue = create_receivable(amount: 100, due_date: reference_date - 2.days)
    upcoming = create_receivable(amount: 300, due_date: reference_date + 15.days)
    canceled = create_receivable(amount: 900, status: "canceled", due_date: reference_date)
    awaiting_trigger = create_receivable(amount: 700, status: "awaiting_trigger", trigger: "case_won", due_date: reference_date)

    summary = Receivables::Summary.new(
      scope: Receivable.where(id: [ due_today, partial, received, overdue, upcoming, canceled, awaiting_trigger ]),
      reference_date: reference_date
    ).call

    assert_equal 2_700.to_d, summary[:expected]
    assert_equal 1_000.to_d, summary[:received]
    assert_equal 1_700.to_d, summary[:open_balance]
  end

  test "separates overdue partial and upcoming balances at the reference date" do
    reference_date = Date.new(2026, 7, 31)
    partial = create_receivable(amount: 500, amount_paid: 200, status: "partial", due_date: reference_date - 1.day)
    overdue = create_receivable(amount: 100, due_date: reference_date - 2.days)
    upcoming = create_receivable(amount: 300, due_date: reference_date + 15.days)
    beyond_window = create_receivable(amount: 400, due_date: reference_date + 31.days)

    summary = Receivables::Summary.new(scope: Receivable.where(id: [ partial, overdue, upcoming, beyond_window ]), reference_date: reference_date).call

    assert_equal 400.to_d, summary[:overdue]
    assert_equal 200.to_d, summary[:partial]
    assert_equal 300.to_d, summary[:upcoming]
  end

  test "groups fully received amounts by payment day" do
    reference_date = Date.new(2026, 7, 31)
    first_payment = create_receivable(amount: 800, amount_paid: 800, status: "received", paid_at: reference_date - 1.day)
    second_payment = create_receivable(amount: 200, amount_paid: 200, status: "received", paid_at: reference_date - 1.day)
    final_payment = create_receivable(amount: 300, amount_paid: 300, status: "received", paid_at: reference_date)
    partial = create_receivable(amount: 500, amount_paid: 100, status: "partial", due_date: reference_date)

    received_by_day = Receivables::Summary.new(scope: Receivable.where(id: [ first_payment, second_payment, final_payment, partial ]), reference_date: reference_date).call[:received_by_day]

    assert_equal({ reference_date - 1.day => 1_000.to_d, reference_date => 300.to_d }, received_by_day)
  end

  test "preserves partial payments from canceled accounts in receipt metrics and the daily chart" do
    reference_date = Date.new(2026, 7, 31)
    canceled_partial = create_receivable(amount: 500, amount_paid: 200, status: "canceled", paid_at: reference_date)
    received = create_receivable(amount: 100, amount_paid: 100, status: "received", paid_at: reference_date)

    summary = Receivables::Summary.new(scope: Receivable.where(id: [ canceled_partial, received ]), reference_date: reference_date).call

    assert_equal 300.to_d, summary[:received]
    assert_equal 200.to_d, summary[:partial]
    assert_equal({ reference_date => 300.to_d }, summary[:received_by_day])
  end

  test "includes financial installment totals without counting replaced legacy accounts" do
    legal_case = create_full_legal_case
    contract = FinancialContract.create!(office: default_office, legal_case: legal_case, fixed_amount: 1_200,
      total_amount: 1_200, installment_count: 2)
    first = contract.installments.create!(number: 1, due_date: Date.new(2026, 7, 31), amount: 600)
    second = contract.installments.create!(number: 2, due_date: Date.new(2026, 8, 15), amount: 600)

    summary = Receivables::Summary.new(
      scope: Receivable.none,
      financial_scope: FinancialInstallment.where(id: [ first, second ]),
      reference_date: Date.new(2026, 7, 31)
    ).call

    assert_equal 1_200.to_d, summary[:expected]
    assert_equal 600.to_d, summary[:open_balance]
    assert_equal 0.to_d, summary[:overdue]
    assert_equal 600.to_d, summary[:upcoming]
  end

  private

  def create_receivable(**attrs)
    Receivable.create!({
      office: default_office,
      description: "Honorários #{SecureRandom.hex(4)}",
      amount: 1_000,
      due_date: Date.current,
      status: "pending",
      trigger: "manual"
    }.merge(attrs))
  end
end
