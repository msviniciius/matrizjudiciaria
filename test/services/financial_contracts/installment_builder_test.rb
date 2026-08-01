require "test_helper"

class FinancialContracts::InstallmentBuilderTest < ActiveSupport::TestCase
  setup do
    legal_case = create_full_legal_case
    @contract = FinancialContract.create!(
      office: default_office,
      legal_case: legal_case,
      fixed_amount: 10_000,
      installment_count: 1,
      total_amount: 10_000
    )
  end

  test "creates one installment for the full contract total" do
    installments = FinancialContracts::InstallmentBuilder.call(
      contract: @contract,
      count: 1,
      first_due_date: Date.new(2026, 8, 5)
    )

    assert_equal 1, installments.size
    assert_equal [ 1 ], installments.map(&:number)
    assert_equal [ 10_000.to_d ], installments.map(&:amount)
    assert_equal [ Date.new(2026, 8, 5) ], installments.map(&:due_date)
    assert_equal 1, @contract.reload.installment_count
  end

  test "splits twelve installments equally and keeps the cent difference in the final installment" do
    installments = FinancialContracts::InstallmentBuilder.call(
      contract: @contract,
      count: 12,
      first_due_date: Date.new(2026, 8, 5)
    )

    assert_equal 12, installments.size
    assert_equal Array.new(11, 833.33.to_d), installments.first(11).map(&:amount)
    assert_equal 833.37.to_d, installments.last.amount
    assert_equal 10_000.to_d, installments.sum(&:amount)
    assert_equal Date.new(2027, 7, 5), installments.last.due_date
    assert_equal 12, @contract.reload.installment_count
  end

  test "rejects installment counts outside the supported range" do
    error = assert_raises(ArgumentError) do
      FinancialContracts::InstallmentBuilder.call(
        contract: @contract,
        count: 13,
        first_due_date: Date.new(2026, 8, 5)
      )
    end

    assert_equal "installment count must be between 1 and 12", error.message
    assert_empty @contract.installments
  end
end
