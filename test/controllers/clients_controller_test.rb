require "test_helper"

class ClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client = Client.create!(
      full_name: "Cliente Teste",
      cpf_cnpj: "12345678901",
      email: "cliente.teste@example.com",
      office: default_office
    )
  end

  test "should get index" do
    get clients_url
    assert_response :success
  end

  test "index JSON exposes the active unit clients snapshot" do
    active_unit = Unit.create!(office: default_office, name: "Contencioso clientes")
    other_unit = Unit.create!(office: default_office, name: "Consultivo clientes")
    active_client = create_client(
      full_name: "Cliente da unidade ativa",
      cpf_cnpj: "22222222222",
      phone: "(98) 99999-1111",
      email: "ativo@example.com",
      city: "São Luís",
      unit: active_unit
    )
    create_full_legal_case(client: active_client, unit: active_unit)
    other_client = create_client(
      full_name: "Cliente de outra unidade",
      cpf_cnpj: "33333333333",
      unit: other_unit
    )
    sign_in_and_select(active_unit)

    get clients_url(format: :json), params: { q: "unidade", cadastro_pendente: "", city: "" }

    assert_response :success
    body = response.parsed_body
    assert_equal default_office.name, body.dig("meta", "office_name")
    assert_equal active_unit.name, body.dig("meta", "unit_name")
    assert_equal 1, body.dig("meta", "total_count")
    assert_equal({ "q" => "unidade", "cadastro_pendente" => "", "city" => "" }, body.fetch("filters"))
    assert_equal clients_path, body.dig("actions", "index")
    assert_equal new_client_path, body.dig("actions", "new")

    client = body.fetch("clients").sole
    assert_equal active_client.id, client.fetch("id")
    assert_equal client_path(active_client), client.fetch("path")
    assert_equal edit_client_path(active_client), client.fetch("edit_path")
    assert_equal client_path(active_client), client.fetch("delete_path")
    assert_equal active_client.full_name, client.fetch("full_name")
    assert_equal active_client.cpf_cnpj, client.fetch("cpf_cnpj")
    assert_equal active_client.phone, client.fetch("phone")
    assert_equal active_client.email, client.fetch("email")
    assert_equal active_client.city, client.fetch("city")
    assert_equal false, client.fetch("cadastro_pendente")
    assert_equal "Completo", client.fetch("status_label")
    assert_equal 1, client.fetch("legal_cases_count")
    assert_equal client_path(active_client), client.fetch("processes_path")
    assert_not_includes body.fetch("clients").map { |entry| entry.fetch("id") }, other_client.id
  end

  test "index JSON filters pending clients by city and serializes blank contact fields as strings" do
    active_unit = Unit.create!(office: default_office, name: "Contencioso filtros")
    matching_client = create_client(
      full_name: "Cadastro pendente São Luís",
      cpf_cnpj: "44444444444",
      cadastro_pendente: true,
      city: "São Luís",
      unit: active_unit
    )
    create_client(
      full_name: "Cadastro completo São Luís",
      cpf_cnpj: "55555555555",
      cadastro_pendente: false,
      city: "São Luís",
      unit: active_unit
    )
    create_client(
      full_name: "Cadastro pendente Imperatriz",
      cpf_cnpj: "66666666666",
      cadastro_pendente: true,
      city: "Imperatriz",
      unit: active_unit
    )
    sign_in_and_select(active_unit)

    get clients_url(format: :json), params: { cadastro_pendente: "true", city: "São Luís" }

    assert_response :success
    body = response.parsed_body
    assert_equal 1, body.dig("meta", "total_count")
    assert_equal({ "q" => "", "cadastro_pendente" => "true", "city" => "São Luís" }, body.fetch("filters"))

    client = body.fetch("clients").sole
    assert_equal matching_client.id, client.fetch("id")
    assert_equal "", client.fetch("phone")
    assert_equal "", client.fetch("email")
    assert_equal "São Luís", client.fetch("city")
  end

  test "should get new" do
    get new_client_url
    assert_response :success
  end

  test "should create client" do
    assert_difference("Client.count") do
      post clients_url, params: { client: {
        full_name: "Novo Cliente",
        cpf_cnpj: "98765432100",
        email: "novo.cliente@example.com",
        office_id: default_office.id
      } }
    end

    assert_redirected_to client_url(Client.last)
  end


  test "should quick create pending client" do
    assert_difference("Client.count") do
      post quick_create_clients_url, params: { client: {
        full_name: "Cliente Rápido",
        cpf_cnpj: "11122233344",
        phone: "(98) 99999-0000",
        dados_gov: "E-mail GOV: gov.com\nSenha GOV: 123456"
      } }, as: :json
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal true, body["cadastro_pendente"]
    assert_equal true, Client.last.cadastro_pendente
    assert_includes Client.last.dados_gov.to_s, "gov.com"
  end

  test "should show client" do
    get client_url(@client)
    assert_response :success
  end

  test "should get edit" do
    get edit_client_url(@client)
    assert_response :success
  end

  test "should update client" do
    patch client_url(@client), params: { client: { full_name: "Cliente Atualizado", cpf_cnpj: @client.cpf_cnpj } }
    assert_redirected_to client_url(@client)
  end

  test "should destroy client" do
    assert_difference("Client.count", -1) do
      delete client_url(@client)
    end

    assert_redirected_to clients_url
  end

  private

  def sign_in_and_select(unit)
    admin = User.create!(
      office: default_office,
      name: "Admin clientes",
      email: "admin-clientes-#{SecureRandom.hex(4)}@example.com",
      role: "admin",
      password: "segredo123",
      password_confirmation: "segredo123"
    )
    post login_path, params: { email: admin.email, password: "segredo123" }
    post unit_session_path, params: { unit_id: unit.id }
  end
end
