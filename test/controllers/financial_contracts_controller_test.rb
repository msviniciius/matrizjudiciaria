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

  test "creates fixed plus percentage contracts from either supported basis" do
    post legal_case_financial_contract_url(@legal_case, format: :json), params: {
      financial_contract: {
        fixed_amount: "1000.00",
        includes_percentage: true,
        percentage: "20.00",
        percentage_basis: "claim_value",
        installment_count: 1,
        first_due_date: "2026-08-10"
      }
    }

    assert_response :success
    assert_equal 3_000.to_d, @legal_case.reload.financial_contract.total_amount

    client_received_case = create_full_legal_case(
      internal_number: "PROC-FINANCEIRO-CLIENTE-001",
      claim_value: 50_000
    )
    post legal_case_financial_contract_url(client_received_case, format: :json), params: {
      financial_contract: {
        fixed_amount: "500.00",
        includes_percentage: true,
        percentage: "25.00",
        percentage_basis: "client_received",
        client_received_amount: "8000.00",
        installment_count: 1,
        first_due_date: "2026-09-10"
      }
    }

    assert_response :success
    assert_equal 2_500.to_d, client_received_case.reload.financial_contract.total_amount
  end

  test "accepts manually adjusted installment values and due dates when they exactly match the total" do
    post legal_case_financial_contract_url(@legal_case, format: :json), params: {
      financial_contract: {
        fixed_amount: "1200.00",
        includes_percentage: false,
        installment_count: 2,
        first_due_date: "2026-08-10",
        installments: [
          { number: 1, amount: "500.00", due_date: "2026-08-15" },
          { number: 2, amount: "700.00", due_date: "2026-10-20" }
        ]
      }
    }

    assert_response :success
    installments = @legal_case.reload.financial_contract.installments
    assert_equal [ 500.to_d, 700.to_d ], installments.map(&:amount)
    assert_equal [ Date.new(2026, 8, 15), Date.new(2026, 10, 20) ], installments.map(&:due_date)
  end

  test "rejects an invalid manual installment schedule without persisting the contract" do
    assert_no_difference([ "FinancialContract.count", "FinancialInstallment.count" ]) do
      post legal_case_financial_contract_url(@legal_case, format: :json), params: {
        financial_contract: {
          fixed_amount: "1200.00",
          includes_percentage: false,
          installment_count: 2,
          first_due_date: "2026-08-10",
          installments: [
            { number: 1, amount: "500.00", due_date: "2026-08-15" },
            { number: 2, amount: "699.99", due_date: "2026-09-15" }
          ]
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.parsed_body.fetch("error"), "sum"
  end

  test "updates a populated contract without moving its existing first due date" do
    contract = create_contract(first_due_date: Date.new(2026, 11, 12), count: 2)

    patch legal_case_financial_contract_url(@legal_case, format: :json), params: {
      financial_contract: {
        fixed_amount: "1500.00",
        includes_percentage: false,
        installment_count: 2
      }
    }

    assert_response :success
    contract.reload
    assert_equal [ Date.new(2026, 11, 12), Date.new(2026, 12, 12) ], contract.installments.map(&:due_date)
    assert_equal [ 750.to_d, 750.to_d ], contract.installments.map(&:amount)
    assert_equal "2026-11-12", response.parsed_body.dig("financial_contract", "first_due_date")
  end

  test "preserves custom installment due dates when an update omits the schedule" do
    contract = create_contract(first_due_date: Date.new(2026, 11, 12), count: 2)
    contract.installments.order(:number).last.update!(due_date: Date.new(2027, 2, 28))

    patch legal_case_financial_contract_url(@legal_case, format: :json), params: {
      financial_contract: {
        fixed_amount: "1500.00",
        includes_percentage: false,
        installment_count: 2
      }
    }

    assert_response :success
    assert_equal [ Date.new(2026, 11, 12), Date.new(2027, 2, 28) ], contract.reload.installments.order(:number).map(&:due_date)
  end

  test "does not change a contract that already has a paid installment" do
    contract = create_contract(first_due_date: Date.new(2026, 11, 12), count: 1)
    contract.installments.first.update!(status: "paid")

    patch legal_case_financial_contract_url(@legal_case, format: :json), params: {
      financial_contract: {
        fixed_amount: "9999.00",
        includes_percentage: false,
        installment_count: 1,
        first_due_date: "2027-01-01"
      }
    }

    assert_response :unprocessable_entity
    assert_equal 1_200.to_d, contract.reload.fixed_amount
    assert_equal Date.new(2026, 11, 12), contract.installments.first.due_date
  end

  test "does not expose a process from another office or another selected unit" do
    other_office = create_other_office
    foreign_user = create_user(office: other_office, role: "admin")
    sign_in(foreign_user)

    post legal_case_financial_contract_url(@legal_case, format: :json), params: valid_contract_params
    assert_response :not_found

    current_unit = Unit.create!(office: default_office, name: "Unidade atual #{SecureRandom.hex(4)}")
    other_unit = Unit.create!(office: default_office, name: "Outra unidade #{SecureRandom.hex(4)}")
    @legal_case.update!(unit: other_unit)
    administrator = create_user(office: default_office, role: "admin")
    sign_in(administrator)
    post unit_session_path, params: { unit_id: current_unit.id }

    post legal_case_financial_contract_url(@legal_case, format: :json), params: valid_contract_params
    assert_response :not_found
  end

  private

  def create_contract(first_due_date:, count:)
    contract = FinancialContract.create!(
      office: default_office,
      legal_case: @legal_case,
      fixed_amount: 1_200,
      installment_count: count,
      total_amount: 1_200
    )
    FinancialContracts::InstallmentBuilder.call(
      contract: contract,
      count: count,
      first_due_date: first_due_date
    )
    contract
  end

  def valid_contract_params
    {
      financial_contract: {
        fixed_amount: "1200.00",
        includes_percentage: false,
        installment_count: 1,
        first_due_date: "2026-08-10"
      }
    }
  end

  def create_user(office:, role:)
    User.create!(
      office: office,
      name: "Usuário financeiro",
      email: "financeiro-#{SecureRandom.hex(4)}@example.com",
      role: role,
      password: "segredo123",
      password_confirmation: "segredo123"
    )
  end

  def sign_in(user)
    post login_path, params: { email: user.email, password: "segredo123" }
  end

  def create_other_office
    Office.create!(
      name: "Outro escritório #{SecureRandom.hex(4)}",
      slug: "outro-escritorio-#{SecureRandom.hex(4)}",
      legal_name: "Outro escritório",
      default_phase: "atendimento_inicial",
      default_status: "em_analise",
      default_priority: "medium"
    )
  end
end
