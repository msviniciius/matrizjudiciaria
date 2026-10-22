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

  test "rejeita deadline que mistura processo e expediente de processos diferentes" do
    other_case = create_full_legal_case
    expediente = @legal_case.expedientes.create!(valid_attributes)
    deadline = Deadline.new(
      legal_case: other_case,
      expediente: expediente,
      title: "Prazo inconsistente",
      deadline_type: :judicial,
      status: :pending
    )

    assert_not deadline.valid?
    assert_includes deadline.errors[:legal_case], "deve ser o mesmo processo do expediente"
  end

  test "bloqueia divergencia de processo em escrita direta no banco" do
    other_case = create_full_legal_case
    deadline = @legal_case.expedientes.create!(valid_attributes).deadline

    assert_raises ActiveRecord::StatementInvalid do
      deadline.update_columns(legal_case_id: other_case.id)
    end
  end

  test "nao aplica configuracao de prazo antes da ciencia" do
    DeadlineSetting.create!(
      office: default_office,
      name: "Prazo judicial padrão",
      deadline_type: :judicial,
      days_to_due: 10,
      default_priority: :high,
      active: true
    )

    expediente = @legal_case.expedientes.create!(valid_attributes)

    assert_nil expediente.reload.deadline.due_date
    assert_nil expediente.deadline.priority
  end

  test "protege no banco contra dois deadlines para o mesmo expediente" do
    expediente = @legal_case.expedientes.create!(valid_attributes)
    timestamp = Time.current

    assert_raises ActiveRecord::RecordNotUnique do
      Deadline.insert_all!([ {
        legal_case_id: @legal_case.id,
        expediente_id: expediente.id,
        title: "Deadline duplicado",
        deadline_type: "judicial",
        status: "pending",
        created_at: timestamp,
        updated_at: timestamp
      } ])
    end
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
