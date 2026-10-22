require "test_helper"

class DeadlineCalculatorTest < ActiveSupport::TestCase
  setup do
    create_case_dependencies
    @legal_case = create_full_legal_case
  end

  test "calcula termo inicial no primeiro dia util apos a ciencia" do
    expediente = create_expediente(data_disponibilizacao: Date.new(2026, 10, 16), quantidade_dias: 3)
    expediente.create_ciencia!(tipo: :expressa, data_ciencia: Date.new(2026, 10, 16))

    DeadlineCalculator.new(expediente.deadline, today: Date.new(2026, 10, 19)).recalcular!

    assert_equal Date.new(2026, 10, 19), expediente.deadline.reload.start_date
    assert_equal Date.new(2026, 10, 21), expediente.deadline.due_date
    assert_equal "in_progress", expediente.deadline.status
  end

  test "conta dias uteis e ignora feriado do escritorio" do
    Feriado.create!(office: default_office, data: Date.new(2026, 10, 20), descricao: "Feriado", ambito: :forense)
    expediente = create_expediente(data_disponibilizacao: Date.new(2026, 10, 19), quantidade_dias: 2)
    expediente.create_ciencia!(tipo: :expressa, data_ciencia: Date.new(2026, 10, 19))

    DeadlineCalculator.new(expediente.deadline, today: Date.new(2026, 10, 19)).recalcular!

    assert_equal Date.new(2026, 10, 22), expediente.deadline.reload.due_date
  end

  test "ajusta somente o vencimento de prazo corrido para o proximo dia util" do
    expediente = create_expediente(
      data_disponibilizacao: Date.new(2026, 10, 23), quantidade_dias: 2, contagem: :corridos
    )
    expediente.create_ciencia!(tipo: :expressa, data_ciencia: Date.new(2026, 10, 23))

    DeadlineCalculator.new(expediente.deadline, today: Date.new(2026, 10, 26)).recalcular!

    assert_equal Date.new(2026, 10, 26), expediente.deadline.reload.start_date
    assert_equal Date.new(2026, 10, 27), expediente.deadline.due_date
  end

  test "duplica a quantidade de dias antes de calcular" do
    expediente = create_expediente(quantidade_dias: 2, prazo_em_dobro: true)
    expediente.create_ciencia!(tipo: :expressa, data_ciencia: Date.new(2026, 10, 19))

    DeadlineCalculator.new(expediente.deadline, today: Date.new(2026, 10, 19)).recalcular!

    assert_equal Date.new(2026, 10, 23), expediente.deadline.reload.due_date
  end

  test "mantem prazo aguardando ciencia sem datas calculadas" do
    expediente = create_expediente
    deadline = DeadlineCalculator.new(expediente.deadline, today: Date.new(2026, 10, 21)).recalcular!

    assert_equal "pending", deadline.status
    assert_nil deadline.start_date
    assert_nil deadline.due_date
  end

  test "marca prazo em curso ou vencido conforme a data de referencia" do
    expediente = create_expediente(quantidade_dias: 2)
    expediente.create_ciencia!(tipo: :expressa, data_ciencia: Date.new(2026, 10, 19))
    deadline = expediente.deadline

    DeadlineCalculator.new(deadline, today: Date.new(2026, 10, 20)).recalcular!
    assert_equal "in_progress", deadline.reload.status

    DeadlineCalculator.new(deadline, today: Date.new(2026, 10, 23)).recalcular!
    assert_equal "overdue", deadline.reload.status
  end

  private

  def create_expediente(**attributes)
    @legal_case.expedientes.create!(
      {
        tipo: :intimacao,
        descricao: "Intimação para manifestação",
        data_disponibilizacao: Date.current,
        quantidade_dias: 5,
        contagem: :uteis,
        prazo_em_dobro: false,
        origem: :manual
      }.merge(attributes)
    )
  end
end
