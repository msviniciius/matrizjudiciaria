require_relative "../clients_test_case"

class ClientsUpdateTest < ClientsSystemTestCase
  test "updates a client through the form" do
    _office, unit, user = create_system_context
    client = create_client_for(
      unit,
      full_name: "Cliente Original",
      cpf_cnpj: "10101010101",
      email: "original@example.com",
      city: "São Luís"
    )

    sign_in_and_select(user, unit)
    visit edit_client_path(client)

    assert_selector "h1", text: "Editar cliente"
    fill_in "client_full_name", with: "Cliente Atualizado"
    fill_in "client_email", with: "atualizado@example.com"
    fill_in "client_city", with: "Imperatriz"
    page.execute_script("document.querySelector('form.app-form').noValidate = true")
    click_on "Salvar cliente"

    assert_text "Cliente atualizado com sucesso."
    assert_current_path client_path(client)
    assert_selector "h1", text: "Cliente Atualizado"
    assert_text "atualizado@example.com"
    assert_equal "Cliente Atualizado", client.reload.full_name
    assert_equal "Imperatriz", client.city
  end

  test "shows validation errors when updating with an invalid email" do
    _office, unit, user = create_system_context
    client = create_client_for(
      unit,
      full_name: "Cliente Válido",
      cpf_cnpj: "12121212121"
    )

    sign_in_and_select(user, unit)
    visit edit_client_path(client)
    fill_in "client_email", with: "email-invalido"
    page.execute_script("document.querySelector('form.app-form').noValidate = true")
    click_on "Salvar cliente"

    assert_current_path client_path(client)
    assert_text "Foram encontrados"
    assert_text "E-mail não é válido"
    assert_equal "Cliente Válido", client.reload.full_name
  end
end
