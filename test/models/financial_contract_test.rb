require "test_helper"

class FinancialContractTest < ActiveSupport::TestCase
  setup do
    @legal_case = create_full_legal_case(claim_value: 50_000)
  end

  test "accepts one fixed contract per process" do
    contract = build_contract

    assert contract.save!, contract.errors.full_messages.join(", ")

    duplicate = build_contract
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:legal_case_id], "já está em uso"
  end

  test "attaches the process contract document" do
    contract = build_contract
    contract.contract_document.attach(
      io: StringIO.new("contrato de honorários"),
      filename: "contrato.txt",
      content_type: "text/plain"
    )

    assert contract.save!, contract.errors.full_messages.join(", ")
    assert contract.contract_document.attached?
  end

  test "rejects a process from another office" do
    other_office = Office.create!(name: "Outro Escritório", slug: "outro-escritorio")
    other_client = create_client(full_name: "Cliente externo", office: other_office)
    other_case = create_full_legal_case(office: other_office, client: other_client)
    contract = build_contract(legal_case: other_case)

    assert_not contract.valid?
    assert_includes contract.errors[:legal_case_id], "não pertence ao escritório atual"
  end

  test "requires percentage and basis only when percentage is enabled" do
    missing_percentage = build_contract(includes_percentage: true, percentage: nil, percentage_basis: nil)
    fixed_only_with_percentage = build_contract(includes_percentage: false, percentage: 30, percentage_basis: "claim_value")

    assert_not missing_percentage.valid?
    assert_includes missing_percentage.errors[:percentage], "não pode ficar em branco"
    assert_includes missing_percentage.errors[:percentage_basis], "não pode ficar em branco"

    assert_not fixed_only_with_percentage.valid?
    assert_includes fixed_only_with_percentage.errors[:percentage], "deve ficar em branco para honorários somente fixos"
    assert_includes fixed_only_with_percentage.errors[:percentage_basis], "deve ficar em branco para honorários somente fixos"
  end

  test "accepts supported percentage bases" do
    claim_value_contract = build_contract(
      includes_percentage: true,
      percentage: 30,
      percentage_basis: "claim_value",
      total_amount: 25_000
    )
    client_received_contract = build_contract(
      includes_percentage: true,
      percentage: 40,
      percentage_basis: "client_received",
      client_received_amount: 30_000,
      total_amount: 17_000
    )

    assert claim_value_contract.valid?, claim_value_contract.errors.full_messages.join(", ")
    assert client_received_contract.valid?, client_received_contract.errors.full_messages.join(", ")
    assert claim_value_contract.percentage_basis_claim_value?
    assert client_received_contract.percentage_basis_client_received?
  end

  test "restricts percentage and installment count" do
    zero_percentage = build_contract(includes_percentage: true, percentage: 0, percentage_basis: "claim_value")
    over_percentage = build_contract(includes_percentage: true, percentage: 101, percentage_basis: "claim_value")
    no_installments = build_contract(installment_count: 0)
    too_many_installments = build_contract(installment_count: 13)

    assert_not zero_percentage.valid?
    assert_not over_percentage.valid?
    assert_not no_installments.valid?
    assert_not too_many_installments.valid?
  end

  test "keeps the process legacy receivables accessible" do
    receivable = @legal_case.receivables.create!(
      office: default_office,
      client: @legal_case.client,
      unit: @legal_case.unit,
      description: "Honorários legados",
      amount: 1_000
    )

    assert_includes @legal_case.reload.receivables, receivable
  end

  private

  def build_contract(attrs = {})
    FinancialContract.new(
      {
        office: default_office,
        legal_case: @legal_case,
        fixed_amount: 10_000,
        includes_percentage: false,
        installment_count: 1,
        total_amount: 10_000
      }.merge(attrs)
    )
  end
end
