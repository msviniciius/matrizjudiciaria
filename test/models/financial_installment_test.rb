require "test_helper"

class FinancialInstallmentTest < ActiveSupport::TestCase
  setup do
    legal_case = create_full_legal_case
    @contract = FinancialContract.create!(
      office: default_office,
      legal_case: legal_case,
      fixed_amount: 1_200,
      installment_count: 1,
      total_amount: 1_200
    )
  end

  test "requires a unique number inside the contract" do
    @contract.installments.create!(number: 1, amount: 1_200, due_date: Date.current)
    duplicate = @contract.installments.build(number: 1, amount: 1_200, due_date: Date.current)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:number], "já está em uso"
  end

  test "accepts positive amounts and pending status" do
    installment = @contract.installments.build(number: 1, amount: 1_200, due_date: Date.current)

    assert installment.valid?, installment.errors.full_messages.join(", ")
    assert installment.status_pending?
  end

  test "rejects nonpositive amounts and invalid numbers" do
    zero_amount = @contract.installments.build(number: 1, amount: 0, due_date: Date.current)
    zero_number = @contract.installments.build(number: 0, amount: 1_200, due_date: Date.current)

    assert_not zero_amount.valid?
    assert_not zero_number.valid?
  end
end
