require "test_helper"

class FinancialContracts::CalculatorTest < ActiveSupport::TestCase
  test "keeps the fixed amount when no percentage is included" do
    total = FinancialContracts::Calculator.call(
      fixed_amount: "10000.00",
      includes_percentage: false,
      percentage: nil,
      percentage_basis: nil,
      claim_value: nil,
      client_received: nil
    )

    assert_equal 10_000.to_d, total
  end

  test "adds the percentage calculated from the claim value" do
    total = FinancialContracts::Calculator.call(
      fixed_amount: "2000.00",
      includes_percentage: true,
      percentage: "30",
      percentage_basis: "claim_value",
      claim_value: "50000.00",
      client_received: nil
    )

    assert_equal 17_000.to_d, total
  end

  test "adds the percentage calculated from the client received amount" do
    total = FinancialContracts::Calculator.call(
      fixed_amount: "2000.00",
      includes_percentage: true,
      percentage: "40",
      percentage_basis: "client_received",
      claim_value: "50000.00",
      client_received: "30000.00"
    )

    assert_equal 14_000.to_d, total
  end

  test "requires the client received amount for the client received basis" do
    error = assert_raises(ArgumentError) do
      FinancialContracts::Calculator.call(
        fixed_amount: "2000.00",
        includes_percentage: true,
        percentage: "30",
        percentage_basis: "client_received",
        claim_value: nil,
        client_received: nil
      )
    end

    assert_equal "client received amount is required", error.message
  end

  test "rejects a percentage outside the supported range" do
    over_limit = assert_raises(ArgumentError) do
      FinancialContracts::Calculator.call(
        fixed_amount: "2000.00",
        includes_percentage: true,
        percentage: "101",
        percentage_basis: "claim_value",
        claim_value: "50000.00",
        client_received: nil
      )
    end

    zero = assert_raises(ArgumentError) do
      FinancialContracts::Calculator.call(
        fixed_amount: "2000.00",
        includes_percentage: true,
        percentage: "0",
        percentage_basis: "claim_value",
        claim_value: "50000.00",
        client_received: nil
      )
    end

    assert_equal "percentage must be between 0 and 100", over_limit.message
    assert_equal "percentage must be between 0 and 100", zero.message
  end
end
