require "test_helper"

class CienciasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @legal_case = create_full_legal_case(internal_number: "PROC-CIE-001")
    @expediente = @legal_case.expedientes.create!(expediente_params)
  end

  test "registra ciencia expressa e recalcula o prazo" do
    post "/ciencias", params: {
      ciencia: { expediente_id: @expediente.id, tipo: "expressa", data_ciencia: Date.current }
    }

    assert_redirected_to legal_case_path(@legal_case)
    assert_equal "expressa", @expediente.reload.ciencia.tipo
    assert_equal "pending", @expediente.deadline.reload.status
    assert_not_nil @expediente.deadline.due_date
  end

  test "registra ciencia expressa em JSON" do
    post "/ciencias", params: {
      ciencia: { expediente_id: @expediente.id, tipo: "expressa", data_ciencia: Date.current }
    }, as: :json

    assert_response :created
    assert_equal @expediente.id, response.parsed_body.dig("ciencia", "expediente_id")
    assert_not_nil response.parsed_body.dig("deadline", "due_date")
  end

  test "rejeita ciencia de expediente de outro escritorio" do
    other_office = create_other_office
    other_client = Client.create!(office: other_office, full_name: "Cliente externo", cpf_cnpj: SecureRandom.hex(6))
    other_case = create_full_legal_case(
      internal_number: "PROC-CIE-OTHER",
      office: other_office,
      client: other_client
    )
    other_expediente = other_case.expedientes.create!(expediente_params)

    assert_no_difference "Ciencia.count" do
      post "/ciencias", params: {
        ciencia: { expediente_id: other_expediente.id, tipo: "expressa", data_ciencia: Date.current }
      }
    end

    assert_response :not_found
  end

  private

  def expediente_params
    {
      tipo: "intimacao",
      descricao: "Intimação para manifestação",
      data_disponibilizacao: Date.current,
      quantidade_dias: 5,
      contagem: "corridos",
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
end
