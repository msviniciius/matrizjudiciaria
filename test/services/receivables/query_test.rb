require "test_helper"

class Receivables::QueryTest < ActiveSupport::TestCase
  test "uses an inclusive 30-day period by default and stays within the office" do
    first_day = create_receivable(due_date: Date.current - 29.days)
    today = create_receivable(due_date: Date.current)
    older = create_receivable(due_date: Date.current - 30.days)
    other_office = create_other_office
    other_office_receivable = create_receivable(office: other_office, due_date: Date.current)

    receivables = Receivables::Query.new(office: default_office, params: {}).call

    assert_includes receivables, first_day
    assert_includes receivables, today
    assert_not_includes receivables, older
    assert_not_includes receivables, other_office_receivable
  end

  test "keeps the consolidated view when no unit is selected" do
    unit = Unit.create!(office: default_office, name: "Contencioso")
    matrix_receivable = create_receivable(unit: nil)
    unit_receivable = create_receivable(unit: unit)

    receivables = Receivables::Query.new(office: default_office, params: {}).call

    assert_includes receivables, matrix_receivable
    assert_includes receivables, unit_receivable
  end

  test "keeps accounts without a due date in the default dashboard period" do
    undated = create_receivable(due_date: nil)

    receivables = Receivables::Query.new(office: default_office, params: {}).call

    assert_includes receivables, undated
  end

  test "filters overdue accounts from their due date instead of their stored status" do
    overdue_pending = create_receivable(status: "pending", due_date: Date.current - 1.day)
    overdue_partial = create_receivable(status: "partial", amount_paid: 100, due_date: Date.current - 1.day)
    current_pending = create_receivable(status: "pending", due_date: Date.current)
    persisted_overdue = create_receivable(status: "overdue", due_date: Date.current + 1.day)

    receivables = Receivables::Query.new(office: default_office, params: { status: "overdue" }).call

    assert_equal [ overdue_pending, overdue_partial ].sort_by(&:id), receivables.to_a.sort_by(&:id)
    assert_not_includes receivables, current_pending
    assert_not_includes receivables, persisted_overdue
  end

  test "filters by a unit that belongs to the office" do
    unit = Unit.create!(office: default_office, name: "Contencioso")
    other_unit = Unit.create!(office: default_office, name: "Consultivo")
    matching = create_receivable(unit: unit)
    create_receivable(unit: other_unit)

    receivables = Receivables::Query.new(office: default_office, params: { unit_id: unit.id }).call

    assert_equal [ matching ], receivables.to_a
  end

  test "returns no accounts for a unit outside the office" do
    other_office = create_other_office
    foreign_unit = Unit.create!(office: other_office, name: "Unidade externa")
    create_receivable
    create_receivable(office: other_office, unit: foreign_unit)

    receivables = Receivables::Query.new(office: default_office, params: { unit_id: foreign_unit.id }).call

    assert_empty receivables
  end

  test "filters the office accounts by period client case and status" do
    client = create_client(full_name: "Cliente filtrado")
    legal_case = create_full_legal_case(client: client)
    matching = create_receivable(client: client, legal_case: legal_case, status: "partial", due_date: Date.current - 2.days)
    create_receivable(client: client, legal_case: legal_case, status: "pending", due_date: Date.current - 2.days)
    create_receivable(status: "partial", due_date: Date.current - 2.days)

    receivables = Receivables::Query.new(
      office: default_office,
      params: {
        period: (Date.current - 3.days)..(Date.current - 1.day),
        client_id: client.id,
        legal_case_id: legal_case.id,
        status: "partial"
      }
    ).call

    assert_equal [ matching ], receivables.to_a
  end

  test "filters by a period received as unpermitted controller parameters" do
    matching = create_receivable(due_date: Date.current - 2.days)
    create_receivable(due_date: Date.current - 4.days)
    params = ActionController::Parameters.new(
      period: {
        start: (Date.current - 3.days).iso8601,
        end: (Date.current - 1.day).iso8601
      }
    )

    receivables = Receivables::Query.new(office: default_office, params: params).call

    assert_equal [ matching ], receivables.to_a
  end

  private

  def create_receivable(office: default_office, **attrs)
    Receivable.create!({
      office: office,
      description: "Honorários",
      amount: 1_000,
      due_date: Date.current,
      status: "pending",
      trigger: "manual"
    }.merge(attrs))
  end

  def create_other_office
    Office.create!(
      name: "Outro Escritório #{SecureRandom.hex(4)}",
      slug: "outro-escritorio-#{SecureRandom.hex(4)}",
      legal_name: "Outro Escritório",
      default_phase: "atendimento_inicial",
      default_status: "em_analise",
      default_priority: "medium"
    )
  end
end
