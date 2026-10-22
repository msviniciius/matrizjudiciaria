require "test_helper"

class RefreshPrazosJobTest < ActiveJob::TestCase
  setup do
    create_case_dependencies
  end

  test "cria ciencia tacita e recalcula o prazo depois do prazo de leitura" do
    legal_case = create_full_legal_case
    expediente = create_expediente(legal_case, data_disponibilizacao: Date.new(2026, 10, 5), quantidade_dias: 2)

    result = RefreshPrazosJob.perform_now(today: Date.new(2026, 10, 16))

    assert_equal 1, result[:processed]
    assert_equal 1, result[:tacit_acknowledgements]
    assert_equal "tacita", expediente.reload.ciencia.tipo
    assert_equal Date.new(2026, 10, 15), expediente.ciencia.data_ciencia
    assert_equal Date.new(2026, 10, 16), expediente.deadline.start_date
    assert_equal Date.new(2026, 10, 19), expediente.deadline.due_date
    assert_equal "in_progress", expediente.deadline.status
  end

  test "recalcula deadlines juridicos com ciencia expressa e atualiza o estado" do
    legal_case = create_full_legal_case
    expediente = create_expediente(legal_case, quantidade_dias: 1)
    expediente.create_ciencia!(tipo: :expressa, data_ciencia: Date.new(2026, 10, 1))

    result = RefreshPrazosJob.perform_now(today: Date.new(2026, 10, 5))

    assert_equal 1, result[:processed]
    assert_equal 0, result[:tacit_acknowledgements]
    assert_equal "overdue", expediente.deadline.reload.status
    assert_equal Date.new(2026, 10, 2), expediente.deadline.due_date
    assert_equal Date.new(2026, 10, 2), legal_case.reload.next_deadline_on
  end

  test "e idempotente ao reprocessar o mesmo expediente" do
    legal_case = create_full_legal_case
    expediente = create_expediente(legal_case, data_disponibilizacao: Date.new(2026, 10, 1))

    2.times { RefreshPrazosJob.perform_now(today: Date.new(2026, 10, 12)) }

    assert_not_nil expediente.reload.ciencia
    assert_equal 1, Ciencia.where(expediente_id: expediente.id).count
  end

  test "processa somente o escritorio informado" do
    first_case = create_full_legal_case
    first_expediente = create_expediente(first_case, data_disponibilizacao: Date.new(2026, 10, 1))
    other_office = Office.create!(name: "Outro Escritório", slug: "outro-escritorio")
    other_client = create_client(full_name: "Outro Cliente", cpf_cnpj: SecureRandom.hex(6), office: other_office)
    other_case = create_full_legal_case(client: other_client, office: other_office)
    other_expediente = create_expediente(other_case, data_disponibilizacao: Date.new(2026, 10, 1))

    result = RefreshPrazosJob.perform_now(office_id: default_office.id, today: Date.new(2026, 10, 12))

    assert_equal 1, result[:processed]
    assert_equal "tacita", first_expediente.reload.ciencia.tipo
    assert_nil other_expediente.reload.ciencia
  end

  test "ignora deadlines manuais mesmo quando estao vencidos" do
    legal_case = create_full_legal_case
    manual_deadline = legal_case.deadlines.create!(
      title: "Prazo manual",
      deadline_type: :internal,
      status: :pending,
      start_date: Date.new(2026, 10, 1),
      due_date: Date.new(2026, 10, 2)
    )

    result = RefreshPrazosJob.perform_now(today: Date.new(2026, 10, 12))

    assert_equal 0, result[:processed]
    assert_equal "pending", manual_deadline.reload.status
    assert_equal Date.new(2026, 10, 2), manual_deadline.due_date
  end

  test "expoe uma interface sincrona perform" do
    assert_equal({ processed: 0, tacit_acknowledgements: 0 }, RefreshPrazosJob.perform(today: Date.new(2026, 10, 12)))
  end

  private

  def create_expediente(legal_case, **attributes)
    legal_case.expedientes.create!(
      {
        tipo: :intimacao,
        descricao: "Intimação para manifestação",
        data_disponibilizacao: Date.new(2026, 10, 1),
        quantidade_dias: 5,
        contagem: :uteis,
        prazo_em_dobro: false,
        origem: :manual
      }.merge(attributes)
    )
  end
end
