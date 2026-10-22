require "test_helper"

class ExpedientesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @legal_case = create_full_legal_case(internal_number: "PROC-EXP-001")
  end

  test "cria expediente e seu prazo dentro do escritorio atual" do
    assert_difference([ "Expediente.count", "Deadline.count" ], 1) do
      post "/expedientes", params: { expediente: expediente_params }
    end

    expediente = Expediente.order(:id).last
    assert_redirected_to legal_case_path(@legal_case)
    assert_equal @legal_case, expediente.legal_case
    assert_equal "pending", expediente.deadline.status
  end

  test "cria expediente em JSON" do
    post "/expedientes", params: { expediente: expediente_params }, as: :json

    assert_response :created
    assert_equal Expediente.order(:id).last.id, response.parsed_body.dig("expediente", "id")
  end

  test "rejeita expediente para processo de outro escritorio" do
    other_office = create_other_office
    other_case = create_full_legal_case(
      internal_number: "PROC-EXP-OTHER",
      office: other_office,
      client: Client.create!(office: other_office, full_name: "Cliente externo", cpf_cnpj: SecureRandom.hex(6))
    )

    assert_no_difference([ "Expediente.count", "Deadline.count" ]) do
      post "/expedientes", params: { expediente: expediente_params.merge(legal_case_id: other_case.id) }
    end

    assert_response :not_found
  end

  test "rejeita expediente fora da unidade ativa" do
    current_unit = Unit.create!(office: default_office, name: "Unidade atual expediente")
    other_unit = Unit.create!(office: default_office, name: "Outra unidade expediente")
    @legal_case.update!(unit: other_unit)
    sign_in_and_select(current_unit)

    assert_no_difference([ "Expediente.count", "Deadline.count" ]) do
      post "/expedientes", params: { expediente: expediente_params }
    end

    assert_response :not_found
  end

  private

  def expediente_params
    {
      legal_case_id: @legal_case.id,
      tipo: "intimacao",
      descricao: "Intimação para manifestação",
      data_disponibilizacao: Date.current,
      quantidade_dias: 5,
      contagem: "uteis",
      prazo_em_dobro: false,
      origem: "manual"
    }
  end

  def create_other_office
    Office.create!(
      name: "Escritório externo #{SecureRandom.hex(4)}",
      slug: "escritorio-externo-#{SecureRandom.hex(4)}",
      default_phase: "atendimento_inicial",
      default_status: "em_analise",
      default_priority: "medium"
    )
  end

  def sign_in_and_select(unit)
    admin = User.create!(
      office: default_office,
      name: "Admin expediente",
      email: "admin-expediente-#{SecureRandom.hex(4)}@example.com",
      role: "admin",
      password: "segredo123",
      password_confirmation: "segredo123"
    )
    post login_path, params: { email: admin.email, password: "segredo123" }
    post unit_session_path, params: { unit_id: unit.id }
  end
end
