require "test_helper"

class FinancialContractsControllerTest < ActionDispatch::IntegrationTest
  setup do
    create_case_dependencies
    @legal_case = create_full_legal_case(
      internal_number: "PROC-FINANCEIRO-001",
      claim_value: 10_000
    )
  end

  test "creates a fixed financial contract and its installments for the process" do
    assert_difference([ "FinancialContract.count", "FinancialInstallment.count" ], 1) do
      post legal_case_financial_contract_url(@legal_case, format: :json), params: {
        financial_contract: {
          fixed_amount: "1200.00",
          includes_percentage: false,
          installment_count: 1,
          first_due_date: "2026-08-10"
        }
      }
    end

    assert_response :success
    contract = @legal_case.reload.financial_contract
    assert_equal 1_200, contract.total_amount
    assert_equal Date.new(2026, 8, 10), contract.installments.first.due_date
    assert_equal "pending", contract.installments.first.status
  end
end
