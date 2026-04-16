require "test_helper"

class ClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client = Client.create!(
      full_name: "Cliente Teste",
      cpf_cnpj: "12345678901",
      email: "cliente.teste@example.com"
    )
  end

  test "should get index" do
    get clients_url
    assert_response :success
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
        email: "novo.cliente@example.com"
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
end
