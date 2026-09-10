require_relative "../clients_test_case"

class ClientsCreateTest < ClientsSystemTestCase
  test "creates a client through the form" do
    _office, unit, user = create_system_context

    sign_in_and_select(user, unit)
    visit new_client_path

    assert_selector "h1", text: "Novo cliente"
    fill_in "client_full_name", with: "Novo Cliente"
    fill_in "client_cpf_cnpj", with: "99999999999"
    fill_in "client_email", with: "novo@example.com"
    fill_in "client_city", with: "São Luís"
    fill_in "client_notes", with: "Cliente criado pelo teste de sistema"
    page.execute_script("document.querySelector('form.app-form').noValidate = true")
    click_on "Cadastrar cliente"

    assert_text "Cliente cadastrado com sucesso."
    assert_current_path %r{\A/clients/\d+\z}
    created_client = Client.find_by!(full_name: "Novo Cliente")
    assert_current_path client_path(created_client)
    assert_selector "h1", text: "Novo Cliente"
    assert_text "novo@example.com"
    assert_equal unit.id, created_client.unit_id
    assert_equal "São Luís", created_client.city
  end

  test "shows validation errors when the email is invalid" do
    _office, unit, user = create_system_context

    sign_in_and_select(user, unit)
    visit new_client_path
    fill_in "client_full_name", with: "Cliente com e-mail inválido"
    fill_in "client_cpf_cnpj", with: "98989898989"
    fill_in "client_email", with: "email-invalido"
    page.execute_script("document.querySelector('form.app-form').noValidate = true")
    click_on "Cadastrar cliente"

    assert_current_path clients_path
    assert_text "Foram encontrados"
    assert_text "E-mail não é válido"
  end
end
