require "test_helper"

class ExpedienteTest < ActiveSupport::TestCase
  setup do
    create_case_dependencies
    @legal_case = create_full_legal_case
  end

  test "cria um deadline juridico pendente sem vencimento ao criar o expediente" do
    assert_difference([ "Expediente.count", "Deadline.count" ], 1) do
      @expediente = @legal_case.expedientes.create!(valid_attributes)
    end

    deadline = @expediente.reload.deadline
    assert_equal @legal_case, @expediente.legal_case
    assert_equal @expediente, deadline.expediente
    assert_equal "pending", deadline.status
    assert_equal "judicial", deadline.deadline_type
    assert_nil deadline.due_date
  end

  test "expediente exige os dados necessarios e aceita seus enums" do
    expediente = Expediente.new(legal_case: @legal_case)

    assert_not expediente.valid?
    assert_includes expediente.errors[:tipo], "não pode ficar em branco"
    assert_includes expediente.errors[:descricao], "não pode ficar em branco"
    assert_includes expediente.errors[:data_disponibilizacao], "não pode ficar em branco"
    assert_includes expediente.errors[:quantidade_dias], "não pode ficar em branco"
    assert_includes expediente.errors[:contagem], "não pode ficar em branco"
    assert_includes expediente.errors[:origem], "não pode ficar em branco"

    assert_equal %w[intimacao citacao despacho sentenca], Expediente.tipos.keys
    assert_equal %w[uteis corridos], Expediente.contagems.keys
    assert_equal %w[manual djma pje], Expediente.origems.keys
  end

  test "rejeita quantidade de dias que nao seja positiva" do
    expediente = Expediente.new(valid_attributes.merge(quantidade_dias: 0))

    assert_not expediente.valid?
    assert_includes expediente.errors[:quantidade_dias], "deve ser maior que 0"
  end

  test "mantem um expediente vinculado ao processo" do
    expediente = @legal_case.expedientes.create!(valid_attributes)

    assert_includes @legal_case.reload.expedientes, expediente
    assert_equal @legal_case, expediente.legal_case
  end

  private

  def valid_attributes
    {
      tipo: :intimacao,
      descricao: "Intimação para manifestação",
      data_disponibilizacao: Date.current,
      quantidade_dias: 5,
      contagem: :uteis,
      prazo_em_dobro: false,
      origem: :manual
    }
  end
end
