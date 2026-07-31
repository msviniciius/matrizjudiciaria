require "test_helper"

class ReceivableTest < ActiveSupport::TestCase
  test "belongs to an office while client and legal case are optional" do
    receivable = Receivable.new(
      office: default_office,
      description: "Honorários iniciais",
      amount: 1_500
    )

    assert receivable.valid?, receivable.errors.full_messages.join(", ")
    assert_equal default_office, receivable.office
    assert_nil receivable.client
    assert_nil receivable.legal_case
  end

  test "rejects a unit from another office" do
    other_office = Office.create!(name: "Outro Escritório", slug: "outro-escritorio")
    foreign_unit = Unit.create!(office: other_office, name: "Unidade Externa", slug: "unidade-externa")
    receivable = build_receivable(unit: foreign_unit)

    assert_not receivable.valid?
    assert_includes receivable.errors[:unit_id], "não pertence ao escritório atual"
  end

  test "rejects a client from another office" do
    other_office = Office.create!(name: "Escritório Externo", slug: "escritorio-externo")
    foreign_client = Client.create!(
      office: other_office,
      full_name: "Cliente Externo",
      cpf_cnpj: SecureRandom.hex(6)
    )
    receivable = build_receivable(client: foreign_client)

    assert_not receivable.valid?
    assert_includes receivable.errors[:client_id], "não pertence ao escritório atual"
  end

  test "rejects a legal case from another office" do
    create_case_dependencies
    other_office = Office.create!(name: "Escritório do Processo", slug: "escritorio-do-processo")
    foreign_client = Client.create!(
      office: other_office,
      full_name: "Cliente do Processo Externo",
      cpf_cnpj: SecureRandom.hex(6)
    )
    foreign_case = create_full_legal_case(office: other_office, client: foreign_client)
    receivable = build_receivable(legal_case: foreign_case)

    assert_not receivable.valid?
    assert_includes receivable.errors[:legal_case_id], "não pertence ao escritório atual"
  end

  test "rejects invalid monetary amounts" do
    zero_amount = build_receivable(amount: 0)
    negative_paid = build_receivable(amount_paid: -1)
    overpaid = build_receivable(amount_paid: 1_501)

    assert_not zero_amount.valid?
    assert_includes zero_amount.errors[:amount], "deve ser maior que 0"
    assert_not negative_paid.valid?
    assert_includes negative_paid.errors[:amount_paid], "deve ser maior ou igual a 0"
    assert_not overpaid.valid?
    assert_includes overpaid.errors[:amount_paid], "deve ser menor ou igual a 1500"
  end

  test "returns the unpaid balance" do
    receivable = build_receivable(amount: 1_500, amount_paid: 400)

    assert_equal 1_100, receivable.balance
  end

  test "registers a partial payment and keeps the account open" do
    receivable = build_receivable(amount: 1_500)
    receivable.save!

    receivable.register_payment!(value: 400, paid_at: Date.new(2026, 7, 31), payment_method: "pix")

    assert_equal 400, receivable.amount_paid
    assert_equal 1_100, receivable.balance
    assert_equal "partial", receivable.status
    assert_nil receivable.paid_at
    assert_equal "pix", receivable.payment_method
  end

  test "settles the account when payments reach its amount" do
    receivable = build_receivable(amount: 1_500, amount_paid: 400)
    receivable.save!
    paid_on = Date.new(2026, 7, 31)

    receivable.register_payment!(value: 1_100, paid_at: paid_on)

    assert_equal 1_500, receivable.amount_paid
    assert_equal 0, receivable.balance
    assert_equal "received", receivable.status
    assert_equal paid_on, receivable.paid_at
  end

  test "rejects zero or negative payments without changing the balance" do
    receivable = build_receivable
    receivable.save!

    [ 0, -100 ].each do |value|
      assert_raises(ArgumentError) do
        receivable.register_payment!(value: value)
      end

      assert_equal 0, receivable.reload.amount_paid
      assert_equal "pending", receivable.status
    end
  end

  test "rejects a received account whose amount has not been fully paid" do
    receivable = build_receivable(status: "received", amount_paid: 0)

    assert_not receivable.valid?
    assert_includes receivable.errors[:status], "só pode ser recebida quando estiver totalmente quitada"
  end

  test "is overdue only when an open account is past due" do
    receivable = build_receivable(due_date: Date.yesterday, status: "pending")
    received = build_receivable(due_date: Date.yesterday, status: "received", amount_paid: 1_500)

    assert receivable.overdue?
    assert_not received.overdue?
  end

  private

  def build_receivable(attrs = {})
    Receivable.new(
      {
        office: default_office,
        description: "Honorários advocatícios",
        amount: 1_500,
        due_date: Date.current + 15.days,
        trigger: "manual",
        status: "pending"
      }.merge(attrs)
    )
  end
end
